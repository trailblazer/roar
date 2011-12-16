require 'roar/representer'
require 'representable/json'

module Roar
  module Representer
    module JSON
      def self.included(base)
        base.class_eval do
          include Representer
          include Representable::JSON
          
          extend ClassMethods
          include InstanceMethods # otherwise Representable overrides our #to_json.
        end
      end
      
      module InstanceMethods
        def to_hash(*args)
          before_serialize(*args)
          super
        end
        
        def from_json(document, options={})
          document ||= "{}" # DISCUSS: provide this for convenience, or better not?
          
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
          {:as => Hyperlink , :collection => true}
        end
      end
      
      
      # Encapsulates a hypermedia link.
      class Hyperlink
        include JSON
        
        property :rel
        property :href
      end
    end
  end
end
