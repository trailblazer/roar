module Roar
  module Client
    # Basic methods needed to implement the ActiveModel API. Gives your model +#attributes+ and +model_name+.
    # Include this for quickly converting an object to a ROAR-compatible monster.
    module ModelMethods
      extend ActiveSupport::Concern
      
      module ClassMethods
        def model_name
          ActiveSupport::Inflector.underscore(self) # We don't use AM::Naming for now.
        end
      end
      
      
      attr_accessor :attributes
      
      def initialize(attributes={})
        @attributes = attributes
      end
    end
  end
end
