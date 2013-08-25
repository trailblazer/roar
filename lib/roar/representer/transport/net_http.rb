require "net/http"
require "uri"

module Roar
  module Representer
    # Implements the (HTTP) transport interface with Net::HTTP.
    module Transport
      # Definitions: every call returns a Response object responding to #body.
      class NetHTTP
        # TODO: generically handle return codes.
        def get_uri(uri, as)
          do_request(Net::HTTP::Get, uri, as)
        end

        def post_uri(uri, body, as)
          do_request(Net::HTTP::Post, uri, as, body)
        end

        def put_uri(uri, body, as)
          do_request(Net::HTTP::Put, uri, as, body)
        end

        def patch_uri(uri, body, as)
          do_request(Net::HTTP::Patch, uri, as, body)
        end

        def delete_uri(uri, as)
          do_request(Net::HTTP::Delete, uri, as)
        end

      private
        def do_request(what, uri, as, body="")
          # DISCUSS: can this be made easier?
          uri   = parse_uri(uri)
          http  = Net::HTTP.new(uri.host, uri.port)
          req   = what.new(uri.request_uri)


          req.content_type  = as
          req["accept"]     = as  # TODO: test me. # DISCUSS: if Accept is not set, rails treats this request as as "text/html".
          req.body          = body if body

          http.request(req)
        end

        def parse_uri(url)
          uri = URI(url)
          raise "Incorrect URL `#{url}`. Maybe you forgot http://?" if uri.instance_of?(URI::Generic)
          uri
        end
      end
    end
  end
end
