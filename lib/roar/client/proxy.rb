module Roar
  module Client
    
    module Proxy
      include Transport
      
      def get_model(uri, klass) # DISCUSS: not directly used in models. USED in EntityProxy.
        body = get_uri(uri).body
        klass.from_xml(body)  # DISCUSS: knows about DE-serialization and representation-type!
      end
    end
  end
  
end
