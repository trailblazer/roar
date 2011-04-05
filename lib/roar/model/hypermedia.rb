require "roar/model"

module Roar
  module Model
    # Adds links methods to the model which can then be used for hypermedia links when
    # representing the model.
    module Hypermedia # TODO: test me.
      def links=(links)
        @links = links.collect do |link|
          Roar::Representer::Roxml::Hyperlink.from_attributes(link)
        end
      end
      
      def links
        @links
      end
    end
  end
end
