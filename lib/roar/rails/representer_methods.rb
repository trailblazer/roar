module Roar
  module Rails
    # Makes Rails URL helpers work in representers. Dependent on Rails.application.
    module RepresenterMethods
      extend ActiveSupport::Concern
      
      included do |base|
        base.class_eval do
          attr_accessor :_controller
          delegate :request, :env, :to => :_controller
          
          include ActionController::UrlFor
          include ::Rails.application.routes.url_helpers
        end
      end
      
      module ClassMethods
        def for_model(represented, controller)
          # DISCUSS: use #for_model_attributes for overriding?
          puts representable_attrs.inspect
          from_attributes(compute_attributes_for(represented)) do |rep| 
            rep.represented = represented
            rep._controller = controller 
          end
        end
        
        def serialize_model(represented, controller)
          for_model(represented, controller).serialize
        end
      end
    end
  end
end
