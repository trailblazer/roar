require 'representable'

module Roar
  module Representer
    def self.included(base)
      base.class_eval do
        include Representable
      end
    end
    
    # Convert representer's attributes to a nested attributes hash.
    def to_attributes
      {}.tap do |attributes|
        self.class.representable_attrs.each do |definition|
          value = public_send(definition.getter)
          
          if definition.typed?
            value = definition.apply(value) do |v|
              v.to_attributes  # applied to each typed attribute (even in collections).
            end
          end
          
          attributes[definition.name] = value
        end
      end
    end
  
  private
    def before_serialize(*)
    end
  end
end
