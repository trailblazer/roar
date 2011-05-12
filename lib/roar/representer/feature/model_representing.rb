module Roar
  module Representer
    module Feature
      module ModelRepresenting
        attr_accessor :represented
        
        def self.included(base)
          base.extend ClassMethods
        end
        
        module ClassMethods
          def for_model(represented)
            from_attributes(compute_attributes_for(represented)) { |rep| rep.represented = represented }
          end
          
          def serialize_model(represented)
            for_model(represented).serialize
          end
          
        private
          def definition_class
            ModelDefinition
          end
          
          # Called in for_model.
          def compute_attributes_for(represented)
            {}.tap do |attributes|
              self.representable_attrs.each do |definition|
                next unless definition.kind_of?(ModelDefinition)  # for now, really only use "our" model attributes.
                definition.compute_attribute_for(represented, attributes)
              end
            end
          end
          
          
        end # ClassMethods
        
        # Properties that are mapped to a model attribute.
        class ModelDefinition < ::Representable::Definition
          def compute_attribute_for(represented, attributes)
            value = represented.send(accessor)
                
            if typed?
              value = apply(value) do |v|
                sought_type.for_model(v)  # applied to each typed attribute (even in collections).
              end
            end
            
            attributes[accessor] = value
          end
        end
      end
      
      
      module ActiveRecordMethods
        def to_nested_attributes # FIXME: works on first level only, doesn't check if we really need to suffix _attributes and is horriby implemented. just for protoyping.  
          attrs = {}
          
          to_attributes.each do |k,v|
          
          
          
          next if k.to_s == "links"  # FIXME: how to skip virtual attributes that are not mapped in a model?
            
            
            attrs[k] = v
            if v.is_a?(Hash) or v.is_a?(Array)
              attrs["#{k}_attributes"] = attrs.delete(k)
            end
          end
          
          attrs
        end
      end
    end
  end
end
