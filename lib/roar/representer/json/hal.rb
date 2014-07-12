require 'roar/representer/json'

module Roar::Representer
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
    #     include Roar::Representer::JSON::HAL
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
          include Roar::Representer::JSON
          include Links       # overwrites #links_definition_options.
          extend ClassMethods # overwrites #links_definition_options, again.
          include Resources

          def representable_mapper(*) # TODO: make this easier to override.
            super.tap do |map|
              map.extend Resources
            end
          end
        end
      end

      module Resources
        # Write the property to the +_embedded+ hash when it's a resource.
        def compile_fragment(bin, doc)
          embedded = ::Roar.representable_1_8? ? bin[:embedded] : bin.options[:embedded]
          return super unless embedded
          super(bin, doc[:_embedded] ||= {})
        end

        def uncompile_fragment(bin, doc)
          embedded = Roar.representable_1_8? ? bin[:embedded] : bin.options[:embedded]
          return super unless embedded
          super(bin, doc["_embedded"] || {})
        end
      end

      module ClassMethods
        def links_definition_options
          super.merge(:as => :_links)
        end
      end

      class LinkCollection < Feature::Hypermedia::LinkCollection
        def initialize(array_rels, *args)
          super(*args)
          @array_rels = array_rels.map(&:to_s)
        end

        def is_array?(rel)
          @array_rels.include?(rel.to_s)
        end
      end

      # Including this module in your representer will render and parse your embedded hyperlinks
      # following the HAL specification: http://stateless.co/hal_specification.html
      #
      #   module SongRepresenter
      #     include Roar::Representer::JSON
      #     include Roar::Representer::JSON::HAL::Links
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
          base.send :include, Feature::Hypermedia
          base.send :include, InstanceMethods
        end

        module InstanceMethods
        private
          def prepare_link_for(href, options)
            return super(href, options) unless options[:array]  # TODO: remove :array and use special instan

            list = href.collect { |opts| Feature::Hypermedia::Hyperlink.new(opts.merge!(:rel => options[:rel])) }
            LinkArray.new(list, options[:rel])
          end

          # TODO: move to LinksDefinition.
          def link_array_rels
            link_configs.collect { |cfg| cfg.first[:array] ? cfg.first[:rel] : nil }.compact
          end
        end


        require 'representable/json/hash'
        module LinkCollectionRepresenter
          include Representable::JSON::Hash

          values :extend => lambda { |item, *|
            puts "representing #{item.inspect} ++++++++++++++++ "

            item.is_a?(Array) ? LinkArrayRepresenter : Roar::Representer::JSON::HyperlinkRepresenter },
            :instance => lambda { |fragment, *| fragment.is_a?(LinkArray) ? fragment : Roar::Representer::Feature::Hypermedia::Hyperlink.new }

          def to_hash(options)
            puts "%%%%%%%%%%%%%%%%%%%%%%%%5 #{self.class.inspect}"
            super.tap do |hsh|  # TODO: cool: super(:exclude => [:rel]).
              puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! #{hsh.inspect}"
              hsh.each { |k,v| v.delete(:rel) }
            end
          end


          def from_hash(hash, options={})
            hash.each { |k,v| hash[k] = LinkArray.new(v, k) if is_array?(k) }

            hsh = super(hash) # this is where :class and :extend do the work.

            hsh.each { |k, v| v.rel = k }
          end
        end

        class LinkArray < Array
          def initialize(elems, rel)
            super(elems)
            @rel = rel
          end

          attr_reader :rel

          def rel=(rel)
            each { |lnk| lnk.rel = rel }
          end
        end

        require 'representable/json/collection'
        module LinkArrayRepresenter
          include Representable::JSON::Collection

          items :extend => Roar::Representer::JSON::HyperlinkRepresenter,
            :class => Roar::Representer::Feature::Hypermedia::Hyperlink

          def to_hash(*)
            super.tap do |ary|
              ary.each { |lnk| rel = lnk.delete(:rel) }
            end
          end
        end


        module ClassMethods
          def links_definition_options
            # property :links_array,
            {
              :as       => :links,
              :extend   => HAL::Links::LinkCollectionRepresenter,
              :instance => lambda { |*| LinkCollection.new(link_array_rels) }, # defined in InstanceMethods as this is executed in represented context.
              :decorator_scope => true,
              # TODO: make it always a hash so we don't need links_array and links.
              :getter => lambda { |*| links },
              :setter => lambda { |v, *| self.links=v }
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
            options[:array] = true  # FIXME: we need to save this information somewhere.
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
