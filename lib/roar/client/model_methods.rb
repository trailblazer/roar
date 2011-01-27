module Roar
  module Client
    # Basic methods needed to implement the ActiveModel API. Gives your model +#attributes+ and +model_name+.
    # Include this for quickly converting an object to a ROAR-compatible monster.
    module ModelMethods
      extend ActiveSupport::Concern
      
      included do
        extend ActiveModel::Naming
      end
      
      attr_accessor :attributes
      
      def initialize(attributes={})
        @attributes = attributes
      end
    end
  end
end
