require 'roar/representer'
require 'roxml'

module Roar
  module Representer
    class Roxml < Base
      include ROXML
      
      def serialize(represented)
        to_xml(represented).serialize
      end
    
    private
      def to_xml(represented)
        attributes = represented.attributes # DISCUSS: dependency to model#attributes.
        
        copy_attributes!(attributes)
        
        super(:name => represented.class.model_name)
      end
      
      
      def copy_attributes!(attributes)
        self.class.roxml_attrs.each do |attr|
          value = attributes[attr.accessor]
          
          public_send("#{attr.accessor}=", value)
        end
      end
      
      
      class << self
        def deserialize(xml)
          from_xml(xml)
        end
        
        def has_one(attr_name, options={})
          if klass = options.delete(:class)
            options[:as] = klass.representer_class_for(mime_type) or raise "No representer found for #{mime_type}"
          end
          
          xml_accessor attr_name, options
        end     
      end
      
      
      # Encapsulates a <link ...>.
      class Hyperlink < self
        xml_accessor :rel,  :from => "@rel"
        xml_accessor :href, :from => "@href"
      end
    end
  end
end


# TODO: don't monkey-patch the original class.
ROXML::XMLObjectRef.module_eval do
private
  def serialize(object)
    representer = opts.sought_type.new
    representer.serialize(object)
  end
  
  def update_xml_for_entity(xml, entity)
    return ROXML::XML.add_child(xml, serialize(entity)) if entity.is_a?(::Roar::Model::Representable)
    update_xml_for_string_entity(xml, entity)
  end
end
