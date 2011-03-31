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
            attributes = {}
            self.roxml_attrs.each do |attr|
              
              # TODO: put that into the concrete representer class/block.
              if attr.accessor == "link"
                puts attr.inspect
                puts "link"
                attributes["link"] = attr.sought_type.for_attributes(:rel => 'article', :href => represented.variant_uri)
                next
              end
              
              value = represented.send(attr.accessor)
               
              value = filter_typed_attribute(attr, value) do |v|
                attr.sought_type.for_model(v)  # applied to each typed attribute (even in collections).
              end
              
              attributes[attr.accessor] = value
            end
            attributes
          end
          
        public
          # TODO: move to RoxmlRep.
          # FIXME: move to Reference#apply
          def filter_typed_attribute(attribute, value)  # TODO: test.
            sub_representer_class = attribute.sought_type
            
            return value unless value and sub_representer_class.is_a?(Class) and sub_representer_class <= Roxml # move to Reference#typed?
            if attribute.array?
              value = value.collect do |item|
                yield item
              end
            else
              value = yield value
            end
            
            value
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
          self.class.roxml_attrs.each do |attr|
            value = public_send(attr.accessor)
                 
            value = self.class.filter_typed_attribute(attr, value) do |typed| # move to Reference#apply
              typed.to_attributes
            end
            
            attributes[attr.accessor] = value
          end
          
          if attributes["link"]
            attributes["variant_uri"] = attributes.delete("link")["href"]
          end
        end # TODO: use Reference#apply here.
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
