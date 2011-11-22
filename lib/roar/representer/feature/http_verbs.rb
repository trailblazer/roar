require 'roar/client/transport'

module Roar
  # Gives HTTP-power to representers where those can automatically serialize, send, process and deserialize HTTP-requests.
  module Representer
    module Feature
      module HttpVerbs
        def self.included(base)
          base.extend ClassMethods
        end
        
        
        module ClassMethods
          include Client::Transport
          
          def get(url, format)  # TODO: test me!
            #url = resource_base + variable_path.to_s
            representation = get_uri(url, format).body
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
        def post!(*args)
          rep = post(*args) # TODO: make this better.
          
          self.class.representable_attrs.each do |definition|

            send(definition.setter, rep.public_send(definition.getter))
          end # TODO: this sucks. do this with #properties and #replace_properties.
        end
        
        def get!(url, format) # FIXME: abstract to #replace_properties
          rep = self.class.get(url, format) # TODO: where's the format? why do we need class here?
          
          self.class.representable_attrs.each do |definition|
            send(definition.setter, rep.public_send(definition.getter))
          end # TODO: this sucks. do this with #properties and #replace_properties.
        end
        
        def put(url, format)
          self.class.put(url, serialize, format)
        end
        
        # TODO: implement delete, patch.
      end
    end
  end
end
