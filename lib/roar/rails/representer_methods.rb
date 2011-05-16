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
          
          extend Conventions
        end
      end
      
      module ClassMethods
        # TODO: test?
        def for_model_with_controller(represented, controller)
          # DISCUSS: use #for_model_attributes for overriding?
          from_attributes(compute_attributes_for(represented)) do |rep| 
            rep.represented = represented
            rep._controller = controller 
          end
        end
        
        # TODO: test?
        def serialize_model_with_controller(represented, controller)
          for_model_with_controller(represented, controller).serialize
        end
      end
      
      # Introduces strongly opinionated convenience methods in Representer.
      module Conventions
        def representation_name
          super.to_s.sub("_representer", "").singularize
        end
        
        def collection(name, options={})
          namespace     = self.name.split("::")[-2] # FIXME: this assumption is pretty opinionated.
          singular_name = name.to_s.singularize
          
          super name, options.reverse_merge(
            :as => "#{namespace}/#{singular_name}Representer".classify.constantize,
            :tag => singular_name)
        end
      end
    end
  end
end
