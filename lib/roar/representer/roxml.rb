module Roar
  module Representer
    class Roxml < Base
      include ROXML
      
      def serialize(attributes)
        to_xml.serialize
      end
      
      def to_xml(*)
        attributes = represented.attributes # DISCUSS: dependency to model#attributes.
        
        self.class.roxml_attrs.each { |attr|
          value = attributes[attr.name]
          
          # TODO: refactor to separate method.
          if value and attr.sought_type.is_a?(Class) and attr.sought_type < Roar::Representer::Base # FIXME: find out if attribute needs a representer itself.
            # wrap the attribute:
            value = attr.sought_type.new(value) # self.item= RoxmlRepresenterFunctionalTest::ItemApplicationXml.new(v)
          end
          
          public_send("#{attr.name}=", value)
        }
        
        super
      end
      
      def deserialize(body)
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
          if klass = options.delete(:class)
            options[:as] = klass.representer_class_for(mime_type) or raise "No representer found for #{mime_type}"
            puts options.inspect
          end
          
          xml_accessor attr_name, options
        end     
      end
      
    end
  end
end
