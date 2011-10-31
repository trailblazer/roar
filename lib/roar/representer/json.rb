require 'roar/representer/base'
require 'representable/json'

module Roar
  module Representer
    module JSON
      def self.included(base)
        base.class_eval do
          include Base
          include Representable::JSON
          
          extend ClassMethods
          include InstanceMethods # otherwise Representable overrides our #to_json.
        end
      end
      
      module InstanceMethods
        def to_json(*args)
          before_serialize(*args)
          super
        end
        
        # Generic entry-point for rendering.
        def serialize(*args)
          to_json(*args)
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
