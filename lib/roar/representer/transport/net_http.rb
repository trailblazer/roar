require 'roar/representer/transport/net_http/request'
require 'roar/representer/transport/errors'

module Roar
  module Representer
    # Implements the (HTTP) transport interface with Net::HTTP.
    module Transport
      # Low-level interface for HTTP. The #get_uri and friends accept an options and an optional block, invoke
      # the HTTP request and return the request object.
      #
      # The following options are available:
      class NetHTTP

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
          Request.new(options).call(what, &block)
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

      const_set(:UnauthorizedError, Roar::Representer::Transport::Errors::ClientErrors::UnauthorizedError)
    end
  end
end
