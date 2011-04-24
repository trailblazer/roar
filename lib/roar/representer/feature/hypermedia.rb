require "roar/model"

module Roar
  module Representer
    module Feature
      # Adds links methods to the model which can then be used for hypermedia links when
      # representing the model.
      module Hypermedia # TODO: test me.
        def links=(links)
          @links = links.collect do |link|
            Roar::Representer::Roxml::Hyperlink.from_attributes(link)
          end
        end
        
        def links
          LinkCollection.new @links
        end
        
        class LinkCollection < Array
          def [](rel)
            link = find { |l| l.rel.to_s == rel.to_s } and return link.href
          end
        end
      end
    end
  end
end
