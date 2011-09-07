module Representer
  module XML
    class Album < Roar::Representer::XML
      self.representation_name= :album
      
      property :id
      property :year
      collection :songs
      
      link :self do
        album_url(represented.id)
      end
      
      link "album-search" do
        album_search_url
      end
    end
  end
end
