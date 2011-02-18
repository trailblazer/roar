module Roar
  module Representer
    class Base
      class_attribute :represented_class
      
      attr_reader :represented
      
      def initialize(represented=nil) # FIXME!
        @represented = represented
      end
    end
  end
end
