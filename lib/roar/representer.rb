module Roar
  # deserialize
  # serialize
  module Representer
    class Base
      class_attribute :represented_class
      class_attribute :mime_type
      
      class << self
        def represents(klass, options) # DISCUSS: what if we don't want to hard-wire these settings into the representer?
          self.represented_class = klass
          self.mime_type = options[:as]
        end
        
      private
        def from_xml(*)
        end
      end
      
      attr_reader :represented
      
      def initialize(represented=nil) # FIXME!
        @represented = represented
      end
      
      # DISCUSS: serialize on instance?
      def serialize(represented, mime_type)
        
      end
      
      #def serialize_model(model)
      #  serialize(model.attributes)
      #end
      
      
    private
      def to_xml(*) # call #serialize instead.
      end
      
    end
  end
end
