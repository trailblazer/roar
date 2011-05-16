#module Representer
  module XML
    class SongRepresenter < Roar::Representer::XML
      self.representation_name= :song
      
      representable_property :title
    end
  end
#end
