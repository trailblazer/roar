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
          links_def = self.class.find_links_definition or return
          links_def.rel2block.each do |link|
            links << links_def.sought_type.from_attributes({  # create Hyperlink representer.
            "rel"   => link[:rel],
            "href"  => run_link_block(link[:block])})
          end
        end
        
        def run_link_block(block)
          instance_exec(&block)
        end
        
        
        class LinkCollection < Array
          def [](rel)
            link = find { |l| l.rel.to_s == rel.to_s } and return link.href
          end
        end
        
        
        module ClassMethods
          # Defines a hypermedia link to be embedded in the document.
          def link(rel, &block)
            unless links = find_links_definition
              links = LinksDefinition.new(:links, links_definition_options)
              representable_attrs << links
            end
            
            links.rel2block << {:rel => rel, :block => block}
          end
          
          def find_links_definition
            representable_attrs.find do |d| d.is_a?(LinksDefinition) end
          end
        end
        
        
        class LinksDefinition < Representable::Definition
          # TODO: hide rel2block in interface.
          def rel2block
            @rel2block ||= []
          end
        end
      end
    end
  end
end 
