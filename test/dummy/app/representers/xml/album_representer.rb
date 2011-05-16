#module Representer
  module XML
    class AlbumRepresenter < Roar::Representer::XML
      self.representation_name= :album
      
      representable_property :id
      representable_property :year
      
    end
  end
#end
