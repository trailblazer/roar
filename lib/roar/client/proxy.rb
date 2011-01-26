require "restfulie"

module Roar
  module Client
    module Transport
      # get_uri
    end
    
    module Proxy
      extend ActiveSupport::Concern
      
    
      module ClassMethods
        def get_uri(uri, as="application/xml")  # Transport.
          # DISCUSS: how to decide as?
          Restfulie.at(uri).accepts(as).raw.get
        end
        
        def get(variable_path)  # Proxy.
          # DISCUSS: resource_uri = host?
          # DISCUSS: URN translation happens here, too?
          url = resource_host + variable_path.to_s
          
          body = get_uri(url).body
          from_xml(body)  # DISCUSS: knows about DE-serialization and representation-type!
        end
      end
    end
  end
end
