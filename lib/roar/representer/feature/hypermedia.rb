require "roar/model"

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
      #     link :self do
      #       "http://orders/#{id}"
      #     end
      module Hypermedia
        def self.included(base)
          base.extend ClassMethods
        end
        
        def serialize(*)
          prepare_links!
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
          links_def = self.class.representable_attrs.find { |d| d.kind_of?(LinksDefinition) } or return
          links_def.rel2block.each do |link|
            links << links_def.sought_type.from_attributes({  # create Hyperlink representer.
            "rel"   => link[:rel],
            "href"  => instance_exec(&link[:block])})  # DISCUSS: run block in representer context? pass attributes as block argument?
          end
        end
        
        
        class LinkCollection < Array
          def [](rel)
            link = find { |l| l.rel.to_s == rel.to_s } and return link.href
          end
        end
        
        
        module ClassMethods
          # Defines an embedded hypermedia link.
          def link(rel, &block)
            unless links = representable_attrs.find { |d| d.is_a?(LinksDefinition)}
              links = LinksDefinition.new(:links, links_definition_options)
              representable_attrs << links
            end
            
            links.rel2block << {:rel => rel, :block => block}
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
