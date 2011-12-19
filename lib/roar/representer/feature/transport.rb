require "net/http"
require "uri"

module Roar
  module Representer
    module Feature
      # Implements the HTTP verbs with Net::HTTP.
      module Transport
        class << self
          # TODO: generically handle return codes/let Restfulie do it.
          def get_uri(uri, as)
            do_request(Net::HTTP::Get, uri, as)
          end
          
          def post_uri(uri, body, as)
            do_request(Net::HTTP::Post, uri, as)
          end
          
          def put_uri(uri, body, as)
            do_request(Net::HTTP::Put, uri, as)
          end
          
          def patch_uri(uri, body, as)
            do_request(Net::HTTP::Patch, uri, as)
          end
          
          def delete_uri(uri, as)
            do_request(Net::HTTP::Delete, uri, as)
          end
        
        private
          def do_request(what, uri, as, body="")
            # DISCUSS: can this be made easier?
            uri   = URI.parse(uri)
            http  = Net::HTTP.new(uri.host, uri.port)
            req   = what.new(uri.request_uri)
            req.content_type  = as
            req.body          = body if body
            http.request(req)
          end
        end
      end
    end
  end
end
