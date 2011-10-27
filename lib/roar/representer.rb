require 'representable'

module Roar
  module Representer
    module Base
      def self.included(base)
        base.class_eval do
          include Representable
          extend ClassMethods
          
          class << self
            alias_method :property, :representable_property
            alias_method :collection, :representable_collection
          end
        end
      end
      
        
      module ClassMethods
        # Creates a representer instance and fills it with +attributes+.
        def from_attributes(attributes)
          new.tap do |representer|
            yield representer if block_given?
            
            representable_attrs.each do |definition|
              definition.populate(representer, attributes)
            end
          end
        end
      end
      
      
      def initialize(properties={})
        properties.each { |p,v| send("#{p}=", v) }  # DISCUSS: check if valid property?
      end
      
      # Convert representer's attributes to a nested attributes hash.
      def to_attributes
        {}.tap do |attributes|
          self.class.representable_attrs.each do |definition|
            value = public_send(definition.accessor)
            
            if definition.typed?
              value = definition.apply(value) do |v|
                v.to_attributes  # applied to each typed attribute (even in collections).
              end
            end
            
            attributes[definition.accessor] = value
          end
        end
      end
    end
    
    class LinksDefinition < Representable::Definition
      def rel2block
        @rel2block ||= []
      end
      
      def populate(representer, *args)
        representer.links ||= []
        
        rel2block.each do |link|
          representer.links << sought_type.from_attributes({  # create Hyperlink representer.
            "rel"   => link[:rel],
            "href"  => representer.instance_exec(&link[:block])})  # DISCUSS: run block in representer context?
        end
      end
    end
    
  end
end

# FIXME: move to some init asset.
Representable::Definition.class_eval do
  # Populate the representer's attribute with the right value.
  def populate(representer, attributes)
    representer.public_send("#{accessor}=", attributes[accessor])
  end
end
