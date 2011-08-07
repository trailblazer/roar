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
    class XML < Base
      include Representable::XML
      
      def serialize
        to_xml.serialize
      end
      
      def self.deserialize(xml)
        from_xml(xml)
      end
      
      
      # Encapsulates a hypermedia <link ...>.
      class Hyperlink < self
        self.representation_name = :link
        
        property :rel,  :from => "@rel"
        property :href, :from => "@href"
      end
      
      
      def self.links_definition_options
        {:tag => :link, :as => [Hyperlink]}
      end
      
      require 'roar/representer/feature/hypermedia'
      include Feature::Hypermedia
    end
  end
end
