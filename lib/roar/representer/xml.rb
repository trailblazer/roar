module Roar
  module Representer
    module Xml
      extend ActiveSupport::Concern
      
      module ClassMethods
        def xml(*)
        end
        
        
        
        
        
        def from_xml(xml)
          deserialized_hash = Hash.from_xml(xml)
          attributes = deserialized_hash[model_name]
          
          # TODO: extract.
          collection_key="item" 
          collection = attributes.delete(collection_key)
          collection = [collection] unless collection.kind_of?(Array)
          attributes[collection_key.pluralize] = collection
          
          new(attributes)
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
