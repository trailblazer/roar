require "active_support/core_ext/hash/conversions"
require "hooks"

module Roar
  module Representer
    module Xml  # DISCUSS: this is a serialization backend for ActiveSupport xml serializer.
      extend ActiveSupport::Concern
      
      included do
        extend Hooks::InheritableAttribute
        inheritable_attr :xml_collections
        self.xml_collections = {}
      end
      
      module ClassMethods
        def xml(*args, &block)
          instance_exec(&block)
        end
        
        def collection(name, options={})
          xml_collections[name] = options
        end
        
        # Deserializes the xml document and creates a new model instance with the parsed attribute hash.
        def from_xml(xml)
          deserialized_hash = Hash.from_xml(xml)  # yes, we use ActiveSupport for the real work.
          attributes = deserialized_hash[model_name]
          
          from_xml_attributes(attributes)
        end
        
        # Backend-specific: Receives hash parsed from <tt>Hash.from_xml</tt> and prepares the abstract hash.
        def from_xml_attributes(attributes)
          # DISCUSS: use a hook here?
          create_collection_attributes_from_xml(attributes)
          #typecast_attributes_from_xml(attributes)
          
          from_attributes(attributes) # generic hash.
        end
        
        # Generic creator. # FIXME: move to Representer base.
        # DISCUSS: semantically identical to #update_attributes
        def from_attributes(attributes)
          new(attributes)
        end
        
        
      protected
        # Since Hash.from_xml doesn't always detect collections we do it here. 
        def create_collection_attributes_from_xml(attributes)
          xml_collections.each do |name, options|
            name        = name.to_s
            collection  = attributes.delete(name.singularize)
            collection  = [collection] unless collection.kind_of?(Array)
            
            # FIXME: extract.
            if klass = options[:class]
              collection = typecast_collection_for(collection, klass) 
            end
            
            attributes[name] = collection
          end
        end
        
        def typecast_collection_for(collection, klass)
          collection.collect { |e| klass.from_xml_attributes(e) }  # FIXME: this must be from_xml_attributes!
        end
      end
      
      
      def to_xml(options={})
        xml_attributes = attributes_for_xml
        
        # from here is render-only:
        options.reverse_merge!  :root => self.class.model_name, # FIXME: second dependency (we know something about the subject)
                                :skip_instruct => true,
                                :skip_types   => true
        
        xml_attributes.to_xml(options)  # let Hash#to_xml do the actual rendering.
      end
      
      # Backend-specific: Returns hash ready for xml rendering by <tt>Hash#to_xml</tt>
      def attributes_for_xml(*)
        serialized = attributes.dup # FIXME: we don't want to override attributes here.
        create_collection_attributes_for_xml(serialized)
      end
      
      def create_collection_attributes_for_xml(attributes)
        self.class.xml_collections.each do |name, options|  # FIXME: provide iterator method with block.
          name        = name.to_s
          collection = attributes.delete(name)
          attributes[name.singularize] = UnwrappedCollection.new(collection)
        end
        attributes
      end
      
      # For item collections that shouldn't be wrapped with a container tag.
    class UnwrappedCollection < Array
      def to_xml(*args)
        each do |e|
          # DISCUSS: we should call #to_tag here.
          e.to_xml(*args) # pass options[:builder] to Hash or whatever. don't like that.
        end
      end
    end
    end
  end
end
