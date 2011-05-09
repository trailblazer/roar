require 'roar/representer'
require 'representable/xml'


module Roar
  # Basic work-flow
  # in:   * representer parses representation
  #       * recognized elements are stored as representer attributes
  # out:  * attributes in representer are assigned - either as hash in #to_xml, by calling #serialize(represented),
  #         by calling representer's accessors (eg in client?) or whatever else
  #       * representation is compiled from representer only
  module Representer
    class XML < Base
      include Representable::XML
      
      def serialize
        #to_xml(:name => represented.class.model_name).serialize
        to_xml.serialize
      end
      
      # DISCUSS: should be abstract in Representer::Base.
      # Convert representer's attributes to a nested attributes hash.
      def to_attributes
        {}.tap do |attributes|
          self.class.representable_attrs.each do |definition|
            value = public_send(definition.accessor)
            
            if definition.typed?
              value = definition.apply(value) do |v|
                v.to_attributes  # applied to each typed attribute (even in collections).
              end
            end
            
            attributes[definition.accessor] = value
          end
        end
      end
      
      
      class << self
        # Creates a representer instance and fills it with +attributes+.
        def from_attributes(attributes)
          new.tap do |representer|
            yield representer if block_given?
            
            representable_attrs.each do |definition|
              definition.populate(representer, attributes)
            end
          end
        end
        
        
        
        def deserialize(xml)
          from_xml(xml)
        end
      end
      
      
      # Encapsulates a <link ...>.
      class Hyperlink < self
        self.representation_name = :link
        representable_property :rel,  :from => "@rel"
        representable_property :href, :from => "@href"
      end
      
      module HyperlinkMethods
        extend ActiveSupport::Concern
        
        module ClassMethods
          
          
          def link(rel, &block)
            unless links = representable_attrs.find { |d| d.is_a?(LinksDefinition)}
              links = LinksDefinition.new(:links, :tag => :link, :as => [Roar::Representer::XML::Hyperlink])
              representable_attrs << links
              add_reader(links) # TODO: refactor in Roxml.
              attr_writer(links.accessor)
            end
            
            links.rel2block << {:rel => rel, :block => block}
          end
        end
        
      end
      include HyperlinkMethods
      
      
    end
  end
end


Representable::Definition.class_eval do
  # Populate the representer's attribute with the right value.
  def populate(representer, attributes)
    representer.public_send("#{accessor}=", attributes[accessor])
  end
end
