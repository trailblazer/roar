require 'roar/representer'
require 'representable/xml'


module Roar
  # Basic work-flow
  # in:   * representer parses representation
  #       * recognized elements are stored as representer attributes
  # out:  * attributes in representer are assigned - either as hash in #to_xml, by calling #serialize(represented),
  #         by calling representer's accessors (eg in client?) or whatever else
  #       * representation is compiled from representer only
  # TODO: make XML a module to include in Hyperlink < Base.
  module Representer
    module XML
      def self.included(base)
        base.class_eval do
          include Base
          include Representable::XML
          extend ClassMethods
          
          require 'roar/representer/feature/hypermedia'
          include Feature::Hypermedia
        end
      end
      
      module ClassMethods
        def links_definition_options
          {:tag => :link, :as => [Hyperlink]}
        end
        
        def deserialize(xml)
          from_xml(xml)
        end
      end
      
      
      def serialize
        to_xml.serialize
      end
      
      
      # Encapsulates a hypermedia <link ...>.
      class Hyperlink
        include XML
        
        self.representation_name = :link
        
        property :rel,  :from => "@rel"
        property :href, :from => "@href"
      end
      
    end
  end
end
