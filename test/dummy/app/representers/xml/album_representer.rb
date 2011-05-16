#module Representer
  module XML
    class AlbumRepresenter < Roar::Representer::XML
      self.representation_name= :album
      
      property :id
      property :year
      collection :songs, :as => SongRepresenter, :tag => :song
      
      link :self do
        album_url(represented.id)
      end
      
      link "album-search" do
        album_search_url
      end
    end
  end
#end
