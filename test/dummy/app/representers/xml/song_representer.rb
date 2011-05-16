#module Representer
  module XML
    class SongRepresenter < Roar::Representer::XML
      self.representation_name= :song
      
      property :title
    end
  end
#end
