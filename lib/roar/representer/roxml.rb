require 'roar/representer'
require 'roxml'

module Roar
  # Basic work-flow
  # in:   * representer parses representation
  #       * recognized elements are stored as representer attributes
  # out:  * attributes in representer are assigned - either as hash in #to_xml, by calling #serialize(represented),
  #         by calling representer's accessors (eg in client?) or whatever else
  #       * representation is compiled from representer only
  module Representer
    
    module ActiveRecordMethods
      def to_nested_attributes # FIXME: works on first level only, doesn't check if we really need to suffix _attributes and is horriby implemented. just for protoyping.  
        attrs = {}
        
        to_attributes.each do |k,v|
        
        
        
        next if k.to_s == "links"  # FIXME: how to skip virtual attributes that are not mapped in a model?
          
          
          
          attrs[k] = v
          if v.is_a?(Hash) or v.is_a?(Array)
            attrs["#{k}_attributes"] = attrs.delete(k)
          end
        end
        
        attrs
      end
      
    end
    
    
    
    class Roxml < Base
      include ROXML
      
      module ModelRepresenting
        def self.included(base)
          base.extend ClassMethods
        end
        
        module ClassMethods
          def for_model(represented) # TODO: move me to ModelWrapper module (and code to instance method).
            from_attributes(compute_attributes_for(represented))
          end
          
          def serialize_model(represented)
            for_model(represented).serialize
          end
          
        private
          # Called in for_model.
          def compute_attributes_for(represented)
            {}.tap do |attributes|
              self.roxml_attrs.each do |definition|
              
              next if definition.name.to_s == "links" or definition.accessor.to_s == "links"  # FIXME: how to skip virtual attributes that are not mapped in a model?
              
              
              
                # alternative reader can be set with :model_reader.
                value = represented.send(definition.accessor)
                
                if definition.typed? and not definition.options[:ficken]
                  value = definition.apply(value) do |v|
                    definition.sought_type.for_model(v)  # applied to each typed attribute (even in collections).
                  end
                end
                
                attributes[definition.accessor] = value
              end
            end
          end
        end # ClassMethods
        
      end
      
      
      
      
      include ModelRepresenting
      
      def serialize
        #to_xml(:name => represented.class.model_name).serialize
        to_xml.serialize
      end
      
      # DISCUSS: should be abstract in Representer::Base.
      # Convert representer's attributes to a nested attributes hash.
      def to_attributes
        {}.tap do |attributes|
          self.class.roxml_attrs.each do |definition|
            value = public_send(definition.accessor)
            
            if definition.typed?
              value = definition.apply(value) do |v|
                v.to_attributes  # applied to each typed attribute (even in collections).
              end
            end
            
            attributes[definition.accessor] = value
            
            definition.options[:to_attributes].call(attributes) if definition.options[:to_attributes]
          end
        end
      end
      
      
      class << self
        # Creates a representer instance and fills it with +attributes+. Note that it executes an optional hook.
        def from_attributes(attributes)
          new.tap do |representer|
            roxml_attrs.each do |definition|
              if block = definition.options[:from_attributes] # DISCUSS: move into Definition?
                definition.instance_exec(attributes, &block)
              end
              
              # FIXME: hook for from_attributes preparation. merge with :from_attributes block!
              if definition.block
                definition.block.call(representer)
              else 
              
              
              representer.public_send("#{definition.accessor}=", attributes[definition.accessor])
              end
            end
          end
        end
        
        
        
        def deserialize(xml)
          from_xml(xml)
        end
      end
      
      
      # Encapsulates a <link ...>.
      class Hyperlink < self
        xml_name :link
        xml_accessor :rel,  :from => "@rel"
        xml_accessor :href, :from => "@href"
      end
      
      module HyperlinkMethods
        extend ActiveSupport::Concern
        module ClassMethods
          def link(rel, &block)
            xml_accessor :links, :tag => :link, :as => [Roar::Representer::Roxml::Hyperlink] do |rep|
              rep.links ||= []
              rep.links << Roar::Representer::Roxml::Hyperlink.from_attributes({"rel" => rel, "href" => rep.instance_exec(&block)})  # DISCUSS: run block in representer context?
            end
          end
        end
        
      end
      include HyperlinkMethods
      
      
    end
  end
end
