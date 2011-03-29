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
        copy_attributes!(represented)
        
        super(:name => represented.class.model_name)
      end
      
      
      def copy_attributes!(represented)
        self.class.roxml_attrs.each do |attr|
          value = represented.send(attr.accessor)
          
          public_send("#{attr.accessor}=", value)
        end
      end
      
      
      class << self
        def deserialize(xml)
          from_xml(xml)
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
    representer = definition.sought_type.new
    representer.serialize(object)
  end
end
