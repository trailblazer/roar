require 'roar/json'

module Roar
  module JSON
    # Including the JSON::HAL module in your representer will render and parse documents
    # following the HAL specification: http://stateless.co/hal_specification.html
    # Links will be embedded using the +_links+ key, nested resources with the +_embedded+ key.
    #
    # Embedded resources can be specified when calling #property or +collection using the
    # :embedded => true option.
    #
    # Link arrays can be defined using +::links+.
    #
    # CURIEs are specified with the - surprise - +::curie+ class method.
    #
    # Example:
    #
    #   module OrderRepresenter
    #     include Roar::JSON::HAL
    #
    #     property :id
    #     collection :items, :class => Item, :extend => ItemRepresenter, :embedded => true
    #
    #     link :self do
    #       "http://orders/#{id}"
    #     end
    #
    #     links :self do
    #       [{:lang => "en", :href => "http://en.hit"},
    #        {:lang => "de", :href => "http://de.hit"}]
    #     end
    #
    #     curies do
    #       [{:name => :doc,
    #         :href => "//docs/{rel}",
    #         :templated => true}
    #       ]
    #     end
    #   end
    #
    # Renders to
    #
    #   "{\"id\":1,\"_embedded\":{\"items\":[{\"value\":\"Beer\",\"_links\":{\"self\":{\"href\":\"http://items/Beer\"}}}]},\"_links\":{\"self\":{\"href\":\"http://orders/1\"}}}"
    module HAL
      def self.included(base)
        base.class_eval do
          include Roar::JSON
          include Links       # overwrites #links_definition_options.
          extend ClassMethods # overwrites #links_definition_options, again.
          include Resources
        end
      end

      module Resources
        def to_hash(*)
          super.tap do |hash|
            embedded = {}
            representable_attrs.find_all do |dfn|
              name = dfn[:as].(nil) # DISCUSS: should we simplify that in Representable?
              next unless dfn[:embedded] and fragment = hash.delete(name)
              embedded[name] = fragment
            end

            hash["_embedded"] = embedded if embedded.any?
            hash["_links"]    = hash.delete("_links") if hash["_links"] # always render _links after _embedded.
          end
        end

        def from_hash(hash, *)
          hash.fetch("_embedded", []).each { |name, fragment| hash[name] = fragment }
          super
        end
      end

      module ClassMethods
        def links_definition_options
          super.merge(:as => :_links)
        end
      end

      # Including this module in your representer will render and parse your embedded hyperlinks
      # following the HAL specification: http://stateless.co/hal_specification.html
      #
      #   module SongRepresenter
      #     include Roar::JSON
      #     include Roar::JSON::HAL::Links
      #
      #     link :self { "http://self" }
      #   end
      #
      # Renders to
      #
      #   {"links":{"self":{"href":"http://self"}}}
      #
      # Note that the HAL::Links module alone doesn't prepend an underscore to +links+. Use the JSON::HAL module for that.
      module Links
        def self.included(base)
          base.extend ClassMethods  # ::links_definition_options
          base.send :include, Hypermedia
          base.send :include, InstanceMethods
        end

        module InstanceMethods
          def _links
            links
          end

        private
          def prepare_link_for(href, options)
            return super(href, options) unless options[:array]  # TODO: remove :array and use special instan

            href.collect { |opts| Hypermedia::Hyperlink.new(opts.merge(rel: options[:rel])) }
          end
        end


        require 'representable/json/collection'
        require 'representable/json/hash'
        # Represents all links for  "_links":  [Hyperlink, [Hyperlink, Hyperlink]]
        class LinkCollectionRepresenter < Representable::Decorator # links could be a simple collection property.
          include Representable::JSON::Collection

          items decorator: ->(options) { options[:input].is_a?(Array) ? LinkArrayRepresenter : SingleLinkRepresenter },
                class:     ->(options) { options[:input].is_a?(Array) ? Array : Hypermedia::Hyperlink }

          def to_hash(options)
            links = {}
            super.each { |hash| links.merge!(hash) } # [{ rel=>{}, rel=>[{}, {}] }]
            links
          end

          def from_hash(hash, *args)
            collection = hash.collect do |rel, value| # "self" => [{"href": "//"}, ] or "self" => {"href": "//"}
              value.is_a?(Array) ? value.collect { |link| link.merge("rel"=>rel) } : value.merge("rel"=>rel)
            end

            super(collection) # [{rel=>self, href=>//}, ..] or {rel=>self, href=>//}
          end
        end

        class SingleLinkRepresenter < Representable::Decorator
          include Representable::JSON::Hash

          def to_hash(*)
            hash = super
            {hash.delete("rel").to_s => hash}
          end
        end

        require 'representable/json/collection'
        # [Hyperlink, Hyperlink]
        module LinkArrayRepresenter
          include Representable::JSON::Collection

          items extend: SingleLinkRepresenter,
                class:  Roar::Hypermedia::Hyperlink

          def to_hash(*)
            links = []
            rel = nil

            super.each { |hash| # [{"self"=>{"href": ..}}, ..]
              rel = hash.keys[0]
              links += hash.values
            }

            {rel.to_s => links} # {"self"=>[{"lang"=>"en", "href"=>"http://en.hit"}, {"lang"=>"de", "href"=>"http://de.hit"}]}
          end
        end


        module ClassMethods
          def links_definition_options
            # property :links_array,
            {
              # collection: false,
              :as       => :links,
              decorator: LinkCollectionRepresenter,
              instance: ->(*) { Array.new }, # defined in InstanceMethods as this is executed in represented context.
              :exec_context => :decorator,
            }
          end

          # Use this to define link arrays. It accepts the shared rel attribute and an array of options per link object.
          #
          #   links :self do
          #     [{:lang => "en", :href => "http://en.hit"},
          #      {:lang => "de", :href => "http://de.hit"}]
          #   end
          def links(options, &block)
            options = {:rel => options} if options.is_a?(Symbol)
            options[:array] = true
            link(options, &block)
          end

          # Add a CURIEs link section as defined in
          #
          # curies do
          #   [{:name => :doc,
          #     :href => "//docs/{rel}",
          #     :templated => true}
          #   ]
          # end
          def curies(&block)
            links(:curies, &block)
          end
        end
      end
    end
  end
end
