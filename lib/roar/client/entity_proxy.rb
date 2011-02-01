require "roar/client/model_methods"
require "roar/representer/xml"
require "active_support/core_ext/module/attr_internal"
require "roar/client/proxy"

module Roar
  module Client
    # Wraps associated objects, they can be retrieved with #finalize!
    # Used e.g. in Representer::Xml.has_proxied.
    class EntityProxy
      # FIXME: where to move me? i do Representable and i use Transport. however, i'm only for clients.
      include Client::ModelMethods
      include Representer::Xml # FIXME: why does EntityProxy know about xml? get this from Representable or so.
      extend Proxy
      
      attr_internal :proxied_resource
      
      
      
      class << self
        attr_accessor :options
        
        def class_for(options)
          Class.new(self).tap { |k| k.options = options }
        end
      
        def model_name
          options[:class].model_name  # proxy!
        end
        
        def from_attributes(attrs)  # FIXME: move to Representable or so.
          new(attrs)
        end
      end
      
      # Get the actual proxied resource.
      def finalize!(*)
        # TODO: move to class.
        # DISCUSS: how to compute uri?
        self.proxied_resource = self.class.get_model(@attributes["uri"], self.class.options[:class])
      end
      
      def attributes
        # DISCUSS: delegate all unknown methods to the proxied object?
        proxied_resource.attributes # proxy!
      end
      
      def attributes_for_xml(*options)
        original_attributes
      end
      
    private
      def original_attributes
        @attributes
      end
    end
  end
end
