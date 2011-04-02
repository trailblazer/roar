require 'roar/representer'
require 'roxml'

module Roar
  # Basic work-flow
  # in:   * representer parses representation
  #       * recognized elements are stored as representer attributes
  # out:  * attributes in representer are assigned - either as hash in #to_xml, by calling #serialize(represented),
  #         by calling representer's accessors (eg in client?) or whatever else
  #       * representation is compiled from representer only
  module Representer
    
    module ActiveRecordMethods
      def to_nested_attributes # FIXME: works on first level only, doesn't check if we really need to suffix _attributes and is horriby implemented. just for protoyping.  
        attrs = {}
        
        to_attributes.each do |k,v|
          attrs[k] = v
          if v.is_a?(Hash) or v.is_a?(Array)
            attrs["#{k}_attributes"] = attrs.delete(k)
          end
        end
        
        attrs
      end
      
    end
    
    
    
    class Roxml < Base
      include ROXML
      
      module ModelRepresenting
        def self.included(base)
          base.extend ClassMethods
        end
        
        module ClassMethods
          def for_model(represented) # TODO: move me to ModelWrapper module (and code to instance method).
            for_attributes(compute_attributes(represented))
          end
          
          def serialize_model(represented)
            for_model(represented).serialize
          end
          
        private
          def compute_attributes(represented)
            {}.tap do |attributes|
              self.roxml_attrs.each do |definition|
                
                # TODO: put that into the concrete representer class/block.
                if definition.accessor == "link"
                  puts definition.inspect
                  puts "link"
                  attributes["link"] = definition.sought_type.for_attributes(:rel => 'article', :href => represented.variant_uri)
                  next
                end
                
                value = represented.send(definition.accessor)
                
                if definition.typed?
                  value = definition.apply(value) do |v|
                    definition.sought_type.for_model(v)  # applied to each typed attribute (even in collections).
                  end
                end
                
                attributes[definition.accessor] = value
              end
            end
          end
        end # ClassMethods
        
      end
      
      
      
      
      include ModelRepresenting
      
      def serialize
        #to_xml(:name => represented.class.model_name).serialize
        to_xml.serialize
      end
      
      # DISCUSS: should be abstract in Representer::Base.
      # Convert representer's attributes to a nested attributes hash.
      def to_attributes
        {}.tap do |attributes|
          self.class.roxml_attrs.each do |definition|
            value = public_send(definition.accessor)
            
            if definition.typed?
              value = definition.apply(value) do |v|
                v.to_attributes  # applied to each typed attribute (even in collections).
              end
            end
            
            attributes[definition.accessor] = value
            
            definition.options[:to_attributes].call(attributes) if definition.options[:to_attributes]
          end
        end
      end
      
      
      class << self
        # Creates a representer instance and fills it with +attributes+.
        def for_attributes(attributes)
          new.tap do |representer|
            attributes.each_pair do |attr, value|
              representer.public_send("#{attr}=", value)
            end
          end
        end
        
        def deserialize(xml)
          from_xml(xml)
        end
      end
      
      
      # Encapsulates a <link ...>.
      class Hyperlink < self
        xml_name :link
        xml_accessor :rel,  :from => "@rel"
        xml_accessor :href, :from => "@href"
      end
    end
  end
end
