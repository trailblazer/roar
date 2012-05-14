require 'ostruct'

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
      module Hypermedia
        def self.included(base)
          base.extend ClassMethods
        end
        
        def before_serialize(options={})
          prepare_links! unless options[:links] == false  # DISCUSS: doesn't work when links are already setup (e.g. from #deserialize).
          super # Representer::Base
        end
        
        def links=(link_list)
          links.replace(link_list)
        end
        
        def links
          @links ||= LinkCollection.new
        end
        
      protected
        # Setup hypermedia links by invoking their blocks. Usually called by #serialize.
        def prepare_links!
          links_def = find_links_definition or return
          
          links_def.rel2block.each do |config|  # config is [{..}, block]
            options = config.first
            options[:href] = run_link_block(config.last) or next
            
            links.update_link(Feature::Hypermedia::Hyperlink.new(options))
          end
        end
        
        def run_link_block(block)
          instance_exec(&block)
        end
        
        def find_links_definition
          representable_attrs.find { |d| d.is_a?(LinksDefinition) }
        end
        
        
        class LinkCollection < Array
          def [](rel)
            link = find { |l| l.rel.to_s == rel.to_s } and return link
          end
          
          # Checks if the link is already contained by querying for its +rel+.
          # If so, it gets replaced. Otherwise, the new link gets appended.
          def update_link(link)
            if i = find_index { |l| l.rel.to_s == link.rel.to_s }
              return self[i] = link
            end
            self << link
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
            LinksDefinition.new(*links_definition_options).tap do |links|
              representable_attrs << links
            end
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
        
        
        # An abstract hypermedia link with +rel+, +href+ and other attributes.
        # Overwrite the Hyperlink.params method if you need more link attributes.
        class Hyperlink < OpenStruct
          def self.params
            [:rel, :href, :media, :title, :hreflang]
          end

          # Default link attributes. These are required for parsing links from
          # XML documents.
          def self.defaults
            self.params.each_with_object({}) { |p, defaults| defaults[p] = nil }
          end

          def initialize(options={})
            super self.class.defaults.merge options
          end
        end
      end
    end
  end
end 
