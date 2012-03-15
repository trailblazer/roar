module Roar
  module Representer
    module Feature
      # Adds #link to the representer to define hypermedia links in the representation.
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
          links_def       = find_links_definition or return
          hyperlink_class = links_def.sought_type
          
          links_def.rel2block.each do |link|          
            hyperlink_representer = hyperlink_class.new.tap do |hyperlink|  # create Hyperlink representer.
              hyperlink.rel   = link[:rel]
              hyperlink.href  = run_link_block(link[:block])
            end
            # Only include link if href not nil
            links.update_link(hyperlink_representer) if hyperlink_representer.href
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
            link = find { |l| l.rel.to_s == rel.to_s } and return link.href
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
          def link(rel, &block)
            unless links = find_links_definition
              links = LinksDefinition.new(:links, links_definition_options)
              representable_attrs << links
            end
            
            links.rel2block << {:rel => rel, :block => block}
          end
          
          def find_links_definition
            representable_attrs.find { |d| d.is_a?(LinksDefinition) }
          end
        end
        
        
        class LinksDefinition < Representable::Definition
          # TODO: hide rel2block in interface.
          def rel2block
            @rel2block ||= []
          end
        end
        
        
        # An abstract hypermedia link with +rel+ and +href+ attributes.
        class Hyperlink
          attr_accessor :rel, :href
          
          def initialize(opts={})
            @rel, @href  = opts[:rel], opts[:href]
          end
        end
      end
    end
  end
end 
