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
            # DISCUSS: split that into #for_model_attributes so it's easier overridable?
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
            value = represented.send(getter)
                
            if typed?
              value = apply(value) do |v|
                sought_type.for_model(v)  # applied to each typed attribute (even in collections).
              end
            end
            
            attributes[name] = value
          end
        end
      end
      
      
      module ActiveRecordMethods
        def to_nested_attributes # FIXME: extract iterating with #to_attributes. 
          {}.tap do |attributes|
            self.class.representable_attrs.each do |definition|
              next unless definition.kind_of?(ModelRepresenting::ModelDefinition)
              
              value = public_send(definition.getter)
              
              if definition.typed?
                value = definition.apply(value) do |v|
                  v.to_nested_attributes  # applied to each typed attribute (even in collections).
                end
              end
              
              key = definition.name
              key = "#{key}_attributes" if definition.typed?
              
              attributes[key] = value
            end
          end
        end
      end
    end
  end
end
