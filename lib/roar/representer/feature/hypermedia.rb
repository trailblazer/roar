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
          base.extend InheritableArray
          #base.send :create_links_definition
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
          ary.each { |lnk| links.add(lnk) }
        end

      private
        def links_definition
          representable_attrs.find { |d| d.is_a?(LinksDefinition) } or [] # FIXME: this is a bug as soon as #links_definition is used somewhere else beside #prepare_links.
        end

        # Setup hypermedia links by invoking their blocks. Usually called by #serialize.
        def prepare_links!(*args)
          # TODO: move this method to _links or something so it doesn't need to be called in #serialize.
          #compile_links_for(links_definition, *args).each do |lnk|
          compile_links_for(representable_attrs.inherited_array(:links), *args).each do |lnk|
            links.add(lnk)  # TODO: move to LinkCollection.new.
          end
        end

        def compile_links_for(configs, *args)
          configs.collect do |config|
            options, block  = config.first, config.last
            href            = run_link_block(block, *args) or next

            prepare_link_for(href, options)
          end.compact # FIXME: make this less ugly.
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

          def add(link)
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
            options = {:rel => options} if options.is_a?(Symbol)
            links_definition << [options, block]
            representable_attrs.inherited_array(:links) << [options, block]
          end

        private
          def create_links_definition
            representable_attrs << links = LinksDefinition.new(*links_definition_options)
            links
          end

          def links_definition
            representable_attrs.find { |d| d.is_a?(LinksDefinition) } or create_links_definition
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

        # TODO: move to separate module
        # DISCUSS: experimental. this will soon be moved to a separate gem
        module InheritableArray
          def representable_attrs
            super.extend(ConfigExtensions)
          end

          module ConfigExtensions
            def inherited_array(name)
              inheritable_arrays[name] ||= []
            end
            def inheritable_arrays
              @inheritable_arrays ||= {}
            end

            def inherit(parent)
              super
              
              parent.inheritable_arrays.keys.each do |k|
                inherited_array(k).push *parent.inherited_array(k).clone
              end
            end
          end
        end
      end
    end
  end
end
