require "restfulie"

module Roar
  module Client
    # Implements the HTTP verbs.
    module Transport
      # TODO: generically handle return codes/let Restfulie do it.
      def get_uri(uri, as="application/xml")
        # DISCUSS: how to decide as?
        Restfulie.at(uri).accepts(as).get # TODO: debugging/logging here.
      end
    end
    
    module Proxy
      include Transport
      
      def get_model(uri, klass) # DISCUSS: not directly used in models. USED in EntityProxy.
        body = get_uri(uri).body
        klass.from_xml(body)  # DISCUSS: knows about DE-serialization and representation-type!
      end
    end
  end
  
end
