module Roar
  module Representer
    module Feature
      # Define hypermedia links in your representations.
      #
      # Example:
      #
      #   class Order
      #     include Roar::Representer::JSON
      #
      #     property :id
      #
      #     link :self do
      #       "http://orders/#{id}"
      #     end
      #
      # If you want more attributes, just pass a hash to #link.
      #
      #     link :rel => :next, :title => "Next, please!" do
      #       "http://orders/#{id}"
      #     end
      #
      # If you need dynamic attributes, the block can return a hash.
      #
      #     link :preview do
      #       {:href => image.url, :title => image.name}
      #     end
      #
      # Sometimes you need values from outside when the representation links are rendered. Just pass them
      # to the render method, they will be available as block parameters.
      #
      #   link :self do |opts|
      #     "http://orders/#{opts[:id]}"
      #   end
      #
      #   model.to_json(:id => 1)
      module Hypermedia
        def self.included(base)
          base.extend ClassMethods
        end

        def before_serialize(options={})
          prepare_links!(options) unless options[:links] == false  # DISCUSS: doesn't work when links are already setup (e.g. from #deserialize).
          super # Representer::Base
        end

        attr_writer :links

        def links
          @links ||= LinkCollection.new
        end

        def links_array
          links.values  # FIXME: move to LinkCollection#to_a.
        end

        def links_array=(ary)
          # FIXME: move to LinkCollection
          self.links= LinkCollection.new
          ary.each do |lnk|
            self.links[lnk.rel.to_s] = lnk
          end
        end

      protected
        # Setup hypermedia links by invoking their blocks. Usually called by #serialize.
        def prepare_links!(*args)
          links_def = find_links_definition or return

          links_def.rel2block.each do |config|  # config is [{..}, block]
            options, block  = config.first, config.last
            href            = run_link_block(block, *args) or next

            prepare_link_for(href, options)
          end
        end

        def prepare_link_for(href, options)
          options.merge! href.is_a?(Hash) ? href : {:href => href}
          links.add(Hyperlink.new(options))
        end

        def run_link_block(block, *args)
          instance_exec(*args, &block)
        end

        def find_links_definition
          representable_attrs.find { |d| d.is_a?(LinksDefinition) }
        end


        class LinkCollection < Hash
          # DISCUSS: make Link#rel return string always.
          def [](rel)
            self[rel.to_s]
          end

          # Checks if the link is already contained by querying for its +rel+.
          # If so, it gets replaced. Otherwise, the new link gets appended.
          def add(link) # FIXME: use Hash API.
            self[link.rel.to_s] = link
          end
        end


        module ClassMethods
          # Declares a hypermedia link in the document.
          #
          # Example:
          #
          #   link :self do
          #     "http://orders/#{id}"
          #   end
          #
          # The block is executed in instance context, so you may call properties or other accessors.
          # Note that you're free to put decider logic into #link blocks, too.
          def link(options, &block)
            links = find_links_definition || create_links

            options = {:rel => options} if options.is_a?(Symbol)
            links.rel2block << [options, block]
          end

          def find_links_definition
            representable_attrs.find { |d| d.is_a?(LinksDefinition) }
          end

        private
          def create_links
           representable_attrs << links = LinksDefinition.new(*links_definition_options)
           links
          end
        end


        class LinksDefinition < Representable::Definition
          # TODO: hide rel2block in interface.
          attr_writer :rel2block

          def rel2block
            @rel2block ||= []
          end

          def clone
            super.tap { |d| d.rel2block = rel2block.clone }
          end
        end


        require "ostruct"
        # An abstract hypermedia link with arbitrary attributes.
        class Hyperlink < OpenStruct
          include Enumerable

          def each(*args, &block)
            marshal_dump.each(*args, &block)
          end

          # FIXME: do we need this method any longer?
          def replace(hash)
            # #marshal_load requires symbol keys: http://apidock.com/ruby/v1_9_3_125/OpenStruct/marshal_load
            marshal_load(hash.inject({}) { |h, (k,v)| h[k.to_sym] = v; h })
          end
        end
      end
    end
  end
end
