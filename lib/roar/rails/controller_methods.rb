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
      
    #private
      def representer_class_for(model_class, format)
        # DISCUSS: upcase and static namespace is not cool, but works for now.
        "Representer::#{format.to_s.upcase}::#{model_class}".constantize
      end
      
      # Returns the deserialized representation as a hash suitable for #create and #update_attributes.
      def representation
        representer = representer_class_for(self.class.represented_class, formats.first).deserialize(request.raw_post)
        representer.to_nested_attributes
      end
      
      
      class Responder < ActionController::Responder
        def display(resource, given_options={})
          # TODO: find the correct representer for #format.
          # TODO: should we infer the represented class per default?
          # TODO: unit-test this method.
          #representer = controller.representer_class_for(resource.class, format)
          representer = controller.representer_class_for(controller.represented_class, format)
          
          # DISCUSS: do that here?
          #representer.extend(RepresenterMethods::ClassMethods)
          
          controller.render given_options.merge!(options).merge!(
            format => representer.serialize_model_with_controller(resource, controller)
          )
        end
        
        # This is the common behavior for formats associated with APIs, such as :xml and :json.
        def api_behavior(error)
          if has_errors?
            controller.render :text => resource.errors, :status => :unprocessable_entity # TODO: which media format? use an ErrorRepresenter shipped with Roar.
          elsif get?
            display resource
          elsif post?
            display resource, :status => :created, :location => api_location
          elsif put?
            display resource
          else
            head :ok
          end
        end
      end
    end
  end
end
