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
              
              if attr.accessor == "link"
                puts attr.inspect
                puts "link"
                attributes["link"] = attr.sought_type.for_attributes(:rel => 'article', :href => represented.variant_uri)
                next
              end
              
              value = represented.send(attr.accessor)
               
              sub_representer_class = attr.sought_type
              
              # TODO: refactor with Roxml.
              if value and sub_representer_class.is_a?(Class) and sub_representer_class <= Roxml
                if attr.array?
                  value = value.collect do |item|
                    sub_representer_class.for_model(item)
                  end
                else
                  value = sub_representer_class.for_model(value)
                end
              end
              
              attributes[attr.accessor] = value
            end
            attributes
          end
        end
      end
      
      
      
      
      include ModelRepresenting
      
      def serialize
        #to_xml(:name => represented.class.model_name).serialize
        to_xml.serialize
      end
      
      class << self
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
