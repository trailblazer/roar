require 'roar/representer'
require 'roar/representer/feature/hypermedia'
require 'representable/xml'

module Roar
  # Includes #from_xml and #to_xml into your represented object.
  # In addition to that, some more options are available when declaring properties.
  module Representer
    module XML
      def self.included(base)
        base.class_eval do
          include Representer
          include Representable::XML

          extend ClassMethods
          include InstanceMethods # otherwise Representable overrides our #to_xml.
        end
      end
      
      module InstanceMethods
        def to_xml(*args)
          before_serialize(*args)
          super
        end
        
        # Generic entry-point for rendering.
        def serialize(*args)
          to_xml(*args)
        end
        
        def deserialize(*args)
          from_xml(*args)
        end
      end
      
      
      module ClassMethods
        include Representable::XML::ClassMethods
        
        def links_definition_options
          [:links, {:from => :link, :class => Feature::Hypermedia::Hyperlink, :collection => true, :extend => XML::HyperlinkRepresenter}]
        end
        
        # Generic entry-point for parsing.
        def deserialize(*args)
          from_xml(*args)
        end
      end
      
      
      require 'representable/xml/hash'
      module HyperlinkRepresenter
        include Representable::XML::AttributeHash
        
        self.representation_wrap = :link
      end
    end
  end
end
