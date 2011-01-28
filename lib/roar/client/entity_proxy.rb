require "roar/client/model_methods"
require "roar/representer/xml"

module Roar
  module Client
    # Wraps associated objects, they can be retrieved with #finalize!
    # Used e.g. in Representer::Xml.has_proxied.
    class EntityProxy
      # FIXME: where to move me? i do Representable and i use Transport. however, i'm only for clients.
      include Client::ModelMethods
      include Representer::Xml # FIXME: why does EntityProxy know about xml? get this from Representable or so.
      
      
      def self.class_for(options)
        Class.new(self).tap { |k| k.options = options }
      end
      
      class << self
        attr_accessor :options
        
        def model_name
          options[:class].model_name  # proxy!
        end
        
        def from_attributes(attrs)  # FIXME: move to Representable or so.
          new(attrs)
        end
      end
    end
  end
end
