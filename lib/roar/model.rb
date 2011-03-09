module Roar
  # Basic methods needed to implement the ActiveModel API. Gives your model +#attributes+ and +model_name+.
  # Include this for quickly converting an object to a ROAR-compatible monster.
  #
  # #DISCUSS: are Models used both on client- and server-side? I'd say hell yeah. 
  module Model
    extend ActiveSupport::Concern
    
    module ClassMethods
      def model_name
        ActiveSupport::Inflector.underscore(self) # We don't use AM::Naming for now.
      end
      
      def accessors(*names)
        names.each do |name|
          class_eval %Q{
            def #{name}=(v)
              attributes["#{name}"] = v
            end
            
            def #{name}
              attributes["#{name}"]
            end
          }
        end
      end
    end
    
    
    attr_accessor :attributes
    
    def initialize(attributes={})
      @attributes = attributes
    end
  end
end
