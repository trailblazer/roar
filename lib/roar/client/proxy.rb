require "restfulie"

module Roar
  module Client
    # Implements the HTTP verbs.
    module Transport
      # TODO: generically handle return codes/let Restfulie do it.
      def get_uri(uri, as="application/xml")
        # DISCUSS: how to decide as?
        Restfulie.at(uri).accepts(as).get
      end
    end
    
    module Proxy
      # needs #resource_host.
      extend ActiveSupport::Concern
      
      module ClassMethods
        include Transport
        
        def get(variable_path)  # Model Proxy. #DISCUSS: move to ModelProxy or so? needed in actual models
          # DISCUSS: resource_uri = host?
          # DISCUSS: URN translation happens here, too?
          url = resource_host + variable_path.to_s
          get_model(url, self)
        end
        
        def get_model(uri, klass) # DISCUSS: not directly used in models.
          body = get_uri(uri).body
          klass.from_xml(body)  # DISCUSS: knows about DE-serialization and representation-type!
        end
        
      end
    end
  end
end
