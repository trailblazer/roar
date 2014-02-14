require "net/http"
require "uri"

module Roar
  module Representer
    # Implements the (HTTP) transport interface with Net::HTTP.
    module Transport
      # Definitions: every call returns a Response object responding to #body.
      class NetHTTP
        # TODO: generically handle return codes.
        def get_uri(uri, as, *args, &block)
          do_request(Net::HTTP::Get, uri, as, nil, *args, &block)
        end

        def post_uri(uri, body, as, *args, &block)
          do_request(Net::HTTP::Post, uri, as, body, *args, &block)
        end

        def put_uri(uri, body, as, *args, &block)
          do_request(Net::HTTP::Put, uri, as, body, *args, &block)
        end

        def patch_uri(uri, body, as, *args, &block)
          do_request(Net::HTTP::Patch, uri, as, body, *args, &block)
        end

        def delete_uri(uri, as, *args, &block)
          do_request(Net::HTTP::Delete, uri, as, nil, *args, &block)
        end

      private
        def do_request(what, uri, as, body="", options={}) # TODO: make Request object only argument.
          uri   = parse_uri(uri)


          # if options[:ssl]
          #   uri.port = Net::HTTP.https_default_port()
          # end


          http  = Net::HTTP.new(uri.host, uri.port)



          if uri.scheme == 'https'
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end



          req   = what.new(uri.request_uri)

          req.basic_auth(*options[:basic_auth]) if options[:basic_auth] # TODO: make this nicer.

          req.content_type  = as
          req["accept"]     = as  # TODO: test me. # DISCUSS: if Accept is not set, rails treats this request as as "text/html".
          req.body          = body if body

          yield req if block_given?

          http.request(req).tap do |res|
            raise UnauthorizedError if res.is_a?(Net::HTTPUnauthorized) # FIXME: make this better. # DISCUSS: abstract all that crap here?
          end
        end

        def parse_uri(url)
          uri = URI(url)
          raise "Incorrect URL `#{url}`. Maybe you forgot http://?" if uri.instance_of?(URI::Generic)
          uri
        end
      end

      class UnauthorizedError < RuntimeError # TODO: raise this from Faraday, too.
      end
    end
  end
end
