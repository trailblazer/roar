module Roar
  module Representer
    module Xml
      extend ActiveSupport::Concern
      
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
          
          # DISCUSS: use a hook here?
          create_collection_attributes_from_xml(attributes)
          #typecast_attributes_from_xml(attributes)
          
          
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
          collection.collect { |e| klass.new(e) }  # FIXME: this must be from_xml!
        end
        
      end
      
      
      
      def to_xml(options={})
        serialized = attributes_for_xml(options)  # FIXME: first dependency
        
        # TODO: extract.
        collection_key="items" 
        collection = serialized.delete(collection_key)
        serialized[collection_key.singularize] = Roar::Representation::UnwrappedCollection.new(collection)
        
        # from here is render-only:
        options.reverse_merge!  :root => self.class.model_name, # FIXME: second dependency (we know something about the subject)
                                :skip_instruct => true,
                                :skip_types   => true
        
        serialized.to_xml(options)  # let Hash#to_xml do the actual rendering.
      end
      
      def attributes_for_xml(*)
        attributes
      end
      
    end
  end
end
