require "net/http"
require "uri"

module Roar
  module Representer
    # Implements the (HTTP) transport interface with Net::HTTP.
    module Transport
      # Low-level interface for HTTP. The #get_uri and friends accept an options and an optional block, invoke
      # the HTTP request and return the request object.
      #
      # The following options are available:
      class NetHTTP
        class Request # TODO: implement me.
          def initialize(options)
            @uri  = parse_uri(options[:url]) # TODO: add :uri.
            @as   = options[:as]
            @body = options[:body]
          end

          def get
            call(Net::HTTP::Get)
          end

        private
          attr_reader :uri, :as, :body

          def parse_uri(url)
            uri = URI(url)
            raise "Incorrect URL `#{url}`. Maybe you forgot http://?" if uri.instance_of?(URI::Generic)
            uri
          end
        end

        def get_uri(*options, &block)
          call(Net::HTTP::Get, *options, &block)
        end

        def post_uri(*options, &block)
          call(Net::HTTP::Post, *options, &block)
        end

        def put_uri(*options, &block)
          call(Net::HTTP::Put, *options, &block)
        end

        def delete_uri(*options, &block)
          call(Net::HTTP::Delete, *options, &block)
        end

        def patch_uri(*options, &block)
          call(Net::HTTP::Patch, *options, &block)
        end

      private
        def call(what, *args, &block)
          options = handle_deprecated_args(args)
          # TODO: generically handle return codes.
          do_request(what, options[:uri], options[:as], options[:body], options, &block)
        end

        def do_request(what, uri, as, body="", options={}) # TODO: remove me.
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

        def handle_deprecated_args(args) # TODO: remove in 1.0.
          if args.size > 1
            warn %{DEPRECATION WARNING: #get_uri, #post_uri, #put_uri, #delete_uri and #patch_uri no longer accept positional arguments. Please call them as follows:
     get_uri(uri: "http://localhost/songs", as: "application/json")
    post_uri(uri: "http://localhost/songs", as: "application/json", body: "{'id': 1}")
Thank you and have a lovely day.}
            return {:uri => args[0], :as => args[1]} if args.size == 2
            return {:uri => args[0], :as => args[2], :body => args[1]}
          end

          args.first
        end

      end

      class UnauthorizedError < RuntimeError # TODO: raise this from Faraday, too.
      end
    end
  end
end
