require 'roar/client/transport'

module Roar
  # Used in Models as convenience, ActiveResource-like methods. # FIXME: currently this is meant for clients like Representers.
  module Representer
    module Feature
      module HttpVerbs
        # needs #resource_base.
        
        #include Client::Proxy
        extend ActiveSupport::Concern
        
        included do |base|
          base.class_attribute :resource_base
        end
        
        module ClassMethods
          include Client::Transport
          
          def get(url)
            #url = resource_base + variable_path.to_s
            representation = get_uri(url).body
            deserialize(representation)
          end
          
          def post(url, body)
            representation = post_uri(url, body).body
            deserialize(representation)
          end
          
        end
        
        # FIXME: fix redundancy.
        def post(url)
            representation = self.class.post_uri(url, serialize).body
            self.class.deserialize(representation)
          end
          # FIXME: fix redundancy.
        def put(url)
            representation = self.class.put_uri(url, serialize).body
            self.class.deserialize(representation)
          end
        
      end
    end
  end
end
