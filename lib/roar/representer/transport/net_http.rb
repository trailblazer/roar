require "net/http"
require "uri"

module Roar
  module Representer
    # Implements the (HTTP) transport interface with Net::HTTP.
    module Transport
      # Definitions: every call returns a Response object responding to #body.
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



        # TODO: generically handle return codes.
        { :get    => Net::HTTP::Get,
          :post   => Net::HTTP::Post,
          :put    => Net::HTTP::Put,
          :delete => Net::HTTP::Delete,
          :patch  => Net::HTTP::Patch
        }.each do |method, mod|
          define_method("#{method}_uri") do |options, &block| # gives us #get_uri, #post_uri and friends.
            call(mod, options, &block)
          end
        end

      private
        def call(what, options, &block)
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

      end

      class UnauthorizedError < RuntimeError # TODO: raise this from Faraday, too.
      end
    end
  end
end
