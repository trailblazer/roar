require 'active_support/core_ext/class/attribute'

module Roar
  module Rails
    module ControllerMethods
      extend ActiveSupport::Concern
      
      included do |base|
        base.responder = Responder
        base.class_attribute :represented_class
      end
      
      module ClassMethods
        # Sets the represented class for the controller.
        def represents(model_class)
          self.represented_class = model_class
        end
      end
      
      
      def representer_class_for(model_class, format)
        # DISCUSS: upcase and static namespace is not cool, but works for now.
        "Representer::#{format.to_s.upcase}::#{model_class}Representer".constantize
      end
      
      
      
      class Responder < ActionController::Responder
        def display(resource, given_options={})
          # TODO: find the correct representer for #format.
          representer = controller.representer_class_for(resource.class, format)
          controller.render given_options.merge!(options).merge!(
            format => representer.serialize_model(resource, controller)
          )
        end
        
        # This is the common behavior for formats associated with APIs, such as :xml and :json.
        def api_behavior(error)
          #raise error unless resourceful?
          if get?
            display resource
          elsif post?
            display resource, :status => :created, :location => api_location
          elsif put?
            display resource
          elsif has_empty_resource_definition?
            display empty_resource, :status => :ok
          else
            head :ok
          end
        end
      end
    end
  end
end
