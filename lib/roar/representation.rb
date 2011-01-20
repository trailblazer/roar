module Roar
  # Serialization
  # requires ActiveModel: #attributes, model_name ???
  # DOC: #to_xml, #as_xml, #to_hash
  module Representation
    extend ActiveSupport::Concern
    include ActiveModel::Serialization
    include ActiveModel::Serializers::Xml
    
    
    def to_hash
      serializable_hash
    end
    
    def as_xml(options={})
      options.reverse_merge!(:skip_instruct  => true)
      to_xml(options)
    end
    
    module ClassMethods
      def from_xml(*args)
        new({}).from_xml(*args) # DISCUSS: make options in .new optional?
      end
      
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
