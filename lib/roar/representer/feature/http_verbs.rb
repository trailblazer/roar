require 'roar/client/transport'

module Roar
  # Used in Models as convenience, ActiveResource-like methods. # FIXME: currently this is meant for clients like Representers.
  module Representer
    module Feature
      module HttpVerbs
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
          
          def post(url, body, format)
            representation = post_uri(url, body, format).body
            deserialize(representation)
          end
          
          def put(url, body, format)
            representation = put_uri(url, body, format).body
            deserialize(representation)
          end
        end
        
        def post(url, format)
          self.class.post(url, serialize, format)
        end
        
        def put(url, format)
          self.class.put(url, serialize, format)
        end
        
        # TODO: implement delete, patch.
      end
    end
  end
end
