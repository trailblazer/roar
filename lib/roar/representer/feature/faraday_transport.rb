begin
  require 'faraday'
rescue LoadError
  puts 'You must add faraday as a dependency to use the FaradayTransport'
end

module Roar
  module Representer
    module Feature
      # Implements the HTTP verbs with Faraday (which can use adapters
      # based on Net::HTTP or libcurl)
      module FaradayTransport
        class << self

          def get_uri(uri, as)
            build_connection(uri, as).get
          end

          def post_uri(uri, body, as)
            build_connection(uri, as).post
          end

          def put_uri(uri, body, as)
            build_connection(uri, as).put
          end

          def patch_uri(uri, body, as)
            build_connection(uri, as).patch
          end

          def delete_uri(uri, as)
            build_connection(uri, as).delete
          end

          private

          def build_connection(uri, as)
            Faraday::Connection.new(
              :url => uri,
              :headers => { :accept => as }
            )
          end
        end
      end
    end
  end
end
