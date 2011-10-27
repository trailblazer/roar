require 'roar/representer'
require 'representable/json'


module Roar
  module Representer
    module JSON
      def self.included(base)
        base.class_eval do
          include Base
          include Representable::JSON
          extend ClassMethods
          
          require 'roar/representer/feature/hypermedia'
          include Feature::Hypermedia
        end
      end
      
      module ClassMethods
        def deserialize(json)
          from_json(json)
        end
        
        # TODO: move to instance method, or remove?
        def links_definition_options
          {:as => [Hyperlink]}
        end
      end
      
      
      def serialize
        to_json
      end
      
      
      # Encapsulates a hypermedia link.
      class Hyperlink
        include JSON
        self.representation_name = :link
        
        property :rel
        property :href
      end
    end
    
  end
end
