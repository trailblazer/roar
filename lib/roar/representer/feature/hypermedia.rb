require "roar/model"

module Roar
  module Representer
    module Feature
      # Adds links methods to the model which can then be used for hypermedia links when
      # representing the model.
      module Hypermedia
        def self.included(base)
          base.extend ClassMethods
        end
        
        def serialize(*)
          prepare_links!
          super # Representer::Base
        end
        
        
        def links=(links)
          @links = LinkCollection.new(links)
        end
        
        def links
          @links
        end
        
      protected
        # Setup hypermedia links by invoking their blocks. Usually called by #serialize.
        def prepare_links!
          self.links ||= []
        
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
        
      end
    end
  end
end 
