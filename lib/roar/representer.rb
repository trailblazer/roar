module Roar
  module Representer
    class Base
      class_attribute :represented_class
      class_attribute :mime_type
      
      class << self
        def represents(klass, options) # DISCUSS: what if we don't want to hard-wire these settings into the representer?
          self.represented_class = klass
          self.mime_type = options[:as]
        end
        
      end
      
      attr_reader :represented
      
      def initialize(represented=nil) # FIXME!
        @represented = represented
      end
    end
  end
end
