require 'roar/representer/transport/net_http'
require 'roar/representer/transport/faraday'  # Do not require here

module Roar
  # Gives HTTP-power to representers. They can serialize, send, process and deserialize HTTP-requests.
  module Representer
    module Feature
      module HttpVerbs

        class << self
          attr_accessor :transport_engine
          
          def included(base)
            base.extend ClassMethods
          end
        end
        self.transport_engine = ::Roar::Representer::Transport::NetHTTP
        

        module ClassMethods
          # GETs +url+ with +format+ and returns deserialized represented object.
          def get(*args)
            new.get(*args)
          end
        end
        
        
        attr_writer :transport_engine
        def transport_engine
          @transport_engine || HttpVerbs.transport_engine
        end
        
        # Serializes the object, POSTs it to +url+ with +format+, deserializes the returned document
        # and updates properties accordingly.
        def post(url, format)
          response = http.post_uri(url, serialize, format)
          handle_response(response)
        end
        
        # GETs +url+ with +format+, deserializes the returned document and updates properties accordingly.
        def get(url, format)
          response = http.get_uri(url, format)
          handle_response(response)
        end
        
        # Serializes the object, PUTs it to +url+ with +format+, deserializes the returned document
        # and updates properties accordingly.
        def put(url, format)
          response = http.put_uri(url, serialize, format)
          handle_response(response)
          self
        end
        
        def patch(url, format)
          response = http.patch_uri(url, serialize, format)
          handle_response(response)
          self
        end

        def delete(url, format)
          http.delete_uri(url, format)
          self
        end

      private
        def handle_response(response)
          document = response.body
          deserialize(document)
        end

        def http
          transport_engine.new
        end
      end
    end
  end
end
