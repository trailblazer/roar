require 'roar/client/proxy'

module Roar
  # Used in Models as convenience, ActiveResource-like methods.
  module Model
    module HttpVerbs
      # needs #resource_base.
      
      include Client::Proxy
      extend ActiveSupport::Concern
      
      included do |base|
        base.class_attribute :resource_base
      end
      
      module ClassMethods
        include Client::Proxy
        
        def get(variable_path)
          # DISCUSS: resource_uri = host?
          # DISCUSS: URN translation happens here, too?
          url = resource_base + variable_path.to_s
          get_model(url, self)
        end
      end
      
    end
  end
end
