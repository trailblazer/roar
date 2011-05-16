#module Representer
  module XML
    class AlbumRepresenter < Roar::Representer::XML
      self.representation_name= :album
      
      representable_property :id
      representable_property :year
      representable_collection :songs, :as => SongRepresenter, :tag => :song
      
      link :self do
        album_url(represented.id)
      end
      
      link "album-search" do
        album_search_url
      end
    end
  end
#end
