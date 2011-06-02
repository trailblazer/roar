require 'roar/representer'
require 'representable/json'


module Roar
  module Representer
    class JSON < Base
      include Representable::JSON
      
      def serialize
        to_json
      end
      
      def self.deserialize(json)
        from_json(json)
      end
      
      # Encapsulates a hypermedia link.
      class Hyperlink < self
        self.representation_name = :link
        
        property :rel
        property :href
      end
      
      def self.links_definition_options
        {:as => [Hyperlink]}
      end
    end
    
  end
end
