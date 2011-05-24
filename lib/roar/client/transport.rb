require "restfulie"

module Roar
  module Client
    # Implements the HTTP verbs by abstracting Restfulie.
    module Transport
      # TODO: generically handle return codes/let Restfulie do it.
      def get_uri(uri, as)
        Restfulie.at(uri).accepts(as).get # TODO: debugging/logging here.
      end
      
      def post_uri(uri, body, as)
        Restfulie.at(uri).as(as).post(body)
      end
      
      def put_uri(uri, body, as)
        Restfulie.at(uri).as(as).put(body)
      end
      
      def patch_uri(uri, body, as)
        Restfulie.at(uri).as(as).patch(body)
      end
      
      def delete_uri(uri, as)
        Restfulie.at(uri).accepts(as).delete # TODO: debugging/logging here.
      end
    end
  end
end
