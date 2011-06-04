require "roar/model"

module Roar
  module Representer
    module Feature
      # Adds links methods to the model which can then be used for hypermedia links when
      # representing the model.
      module Hypermedia # TODO: test me.
        extend ActiveSupport::Concern
        
        def links=(links)
          @links = LinkCollection.new(links)
        end
        
        def links
          @links
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
              #add_reader(links) # TODO: refactor in Roxml.
#              attr_writer(links.accessor)
            end
            
            links.rel2block << {:rel => rel, :block => block}
          end
        end
        
      end
    end
  end
end 
