module Roar
  module Representer
    class Roxml < Base
      include ROXML
      
      def serialize(attributes)
        to_xml.serialize
      end
      
      def to_xml(*)
        represented.attributes.each do |k,v|  # FIXME: replace with xml_attributes from roxml.
          send("#{k}=", v)
        end
        
        # FIXME: generic model->representer.
        self.class.roxml_attrs.each { |attr| 
          #puts attr.sought_type.inspect
        
          if attr.name == "item"
            v = represented.send(:item)
            
            self.item= RoxmlRepresenterFunctionalTest::ItemApplicationXml.new(v) if v
          end
        }
        
        super
      end
      
      
      
      
      
      def deserialize(body)
        representer = self.class.from_xml(body, "application/xml")
        
        attributes = {}
        representer.roxml_references.collect do |a|
          attributes[a.name] = representer.send(a.name)
        end
        attributes
      end
      
      class << self
        def from_xml(data, *initialization_args)    # overwritten from roxml.
        xml = ROXML::XML::Node.from(data)
        
        config = roxml_attrs.collect { |attr| attr.to_ref(nil, self) }  # FIXME: see Definition#initialize
        
        represented = represented_class.new(*initialization_args) # DISCUSS: *args useful?
        
        
        config.each do |ref|
          value = ref.value_in(xml)
          represented.respond_to?(ref.opts.setter) \
              ? represented.send(ref.opts.setter, value) \
              : represented.instance_variable_set(ref.opts.instance_variable_name, value)
        end
        
        represented
      end
      
      
      
        def has_one(attr_name, options={})
          if options[:class] 
          options.delete(:class)
            options[:as] = RoxmlRepresenterFunctionalTest::ItemApplicationXml#options.delete(:class) 
          end
          
          xml_accessor attr_name, options
        end
        
      end
      
    end
  end
end
