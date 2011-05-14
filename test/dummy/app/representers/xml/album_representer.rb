#module Representer
  module XML
    class AlbumRepresenter < Roar::Representer::XML
      include Roar::Representer::Feature::ModelRepresenting
      include Roar::Representer::Feature::ActiveRecordMethods  # to_nested_attributes
      include Roar::Rails::RepresenterMethods
      
      puts "AlbumRepresenter eval: #{definition_class}"
      puts "#{method(:serialize_model).inspect}"
      self.representation_name= :album
      
      representable_property :id
      representable_property :year
      
    end
  end
#end
