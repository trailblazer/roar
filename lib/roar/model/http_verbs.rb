require 'roar/client/proxy'

module Roar
  # Used in Models as convenience, ActiveResource-like methods.
  module Model
    module HttpVerbs
      # needs #resource_host.
      
      include Client::Proxy
      extend ActiveSupport::Concern
      
      module ClassMethods
        include Client::Proxy
        
        def get(variable_path)
          # DISCUSS: resource_uri = host?
          # DISCUSS: URN translation happens here, too?
          url = resource_host + variable_path.to_s
          get_model(url, self)
        end
      end
      
    end
  end
end
