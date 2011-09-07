module Representer
  module XML
    class Song < Roar::Representer::XML
      self.representation_name= :song
      
      property :title
    end
  end
end
