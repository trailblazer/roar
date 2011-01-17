module Roar
  # Serialization
  # requires ActiveModel: #attributes, model_name ???
  # DOC: #to_xml, #as_xml, #to_hash
  module Representation
    include ActiveModel::Serialization
    include ActiveModel::Serializers::Xml
    
    
    def to_hash
      serializable_hash
    end
    
    def as_xml(options={})
      options.reverse_merge!(:skip_instruct  => true)
      to_xml(options)
    end
  end
end
