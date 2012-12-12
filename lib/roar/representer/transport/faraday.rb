require 'faraday'

module Roar
  module Representer
    module Transport
      # Advanced implementation of the HTTP verbs with the Faraday HTTP library
      # (which can, in turn, use adapters based on Net::HTTP or libcurl)
      #
      # Depending on how the Faraday middleware stack is configured, this
      # Transport can support features such as HTTP error code handling,
      # redirects, etc.
      #
      # @see http://rubydoc.info/gems/faraday/file/README.md Faraday README
      class Faraday

        def get_uri(uri, as)
          build_connection(uri, as).get
        end

        def post_uri(uri, body, as)
          build_connection(uri, as).post(nil, body)
        end

        def put_uri(uri, body, as)
          build_connection(uri, as).put(nil, body)
        end

        def patch_uri(uri, body, as)
          build_connection(uri, as).patch(nil, body)
        end

        def delete_uri(uri, as)
          build_connection(uri, as).delete
        end

        private

        def build_connection(uri, as)
          ::Faraday::Connection.new(
            :url => uri,
            :headers => { :accept => as, :content_type => as }
          ) do |builder|
            builder.use ::Faraday::Response::RaiseError
            builder.adapter ::Faraday.default_adapter
          end
        end
      end
    end
  end
end
