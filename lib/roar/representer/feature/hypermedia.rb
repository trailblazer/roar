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

        # TODO: the whole declarative setup in representable should happen on instance level so we don't need to share methods between class and instance.
        module LinksDefinitionMethods
        private
          def create_links_definition
            representable_attrs << links = LinksDefinition.new(*links_definition_options)
            links
          end

          def links_definition
            representable_attrs.find { |d| d.is_a?(LinksDefinition) } or create_links_definition
          end
        end
        include LinksDefinitionMethods
        def links_definition_options  # FIXME: make this unnecessary.
          self.class.links_definition_options
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

      private
        # Setup hypermedia links by invoking their blocks. Usually called by #serialize.
        def prepare_links!(*args)
          links_definition.each do |config|  # config is [{..}, block]
            options, block  = config.first, config.last
            href            = run_link_block(block, *args) or next

            links.add(prepare_link_for(href, options))
          end
        end

        def prepare_link_for(href, options)
          options.merge! href.is_a?(Hash) ? href : {:href => href}
          Hyperlink.new(options)
        end

        def run_link_block(block, *args)
          instance_exec(*args, &block)
        end


        class LinkCollection < Hash
          # DISCUSS: make Link#rel return string always.
          def [](rel)
            self.fetch(rel.to_s, nil)
          end

          def add(link) # FIXME: use Hash API.
            self[link.rel.to_s] = link
          end
        end


        module ClassMethods
          include LinksDefinitionMethods
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
            options = {:rel => options} if options.is_a?(Symbol)
            links_definition << [options, block]
          end
        end


        class LinksDefinition < Representable::Definition
          include Enumerable

          attr_accessor :rel2block
          def initialize(*)
            super
            @rel2block = []
          end

          def <<(args)
            rel2block << args
          end

          def each(*args, &block)
            rel2block.each(*args, &block)
          end

          # DISCUSS: where do we need this?
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
