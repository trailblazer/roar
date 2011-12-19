require 'test_helper'
require 'roar/representer/json'
require 'roar/representer/feature/hypermedia'

class IntegrationTest < MiniTest::Spec
  class Beer
    include Roar::Representer::JSON
    include Roar::Representer::Feature::Hypermedia
    
    property :name
    
    link :self do
      "http://beers/#{name.downcase}"
    end
  end
  
  class Beers
    include Roar::Representer::JSON
    include Roar::Representer::Feature::Hypermedia
    
    collection :items, :class => Beer
  end
  
  describe "Beer service" do
    it "provides a document for a particular beer" do
      assert_equal "{\"beer\":{\"name\":\"Eisenbahn\",\"links\":[{\"rel\":\"self\",\"href\":\"http://beers/eisenbahn\"}]}}", Beer.from_attributes(name: "Eisenbahn").to_json
    end
    
    it "provides a detailed beers list" do
      beers = ["Jever", "Becks", "Eisenbahn", "Colorado"].collect do |name|
        Beer.from_attributes(name: name)
      end
      
      
      list = Beers.new
      list.items = beers
      
      assert_equal "{\"beers\":{\"items\":[{\"name\":\"Jever\",\"links\":[{\"rel\":\"self\",\"href\":\"http://beers/jever\"}]},{\"name\":\"Becks\",\"links\":[{\"rel\":\"self\",\"href\":\"http://beers/becks\"}]},{\"name\":\"Eisenbahn\",\"links\":[{\"rel\":\"self\",\"href\":\"http://beers/eisenbahn\"}]},{\"name\":\"Colorado\",\"links\":[{\"rel\":\"self\",\"href\":\"http://beers/colorado\"}]}]}}", list.to_json
    end
    
    it "provides a pageable beers list without details" do
      class BeerCollection
        include Roar::Representer::JSON
        include Roar::Representer::Feature::Hypermedia
        
        attr_accessor :per_page, :current_page, :all_items
        
        collection :beers, :class => Beer
        property :total
        
        def total
          all_items.size
        end
        
        def beers
          all_items[(current_page-1)*per_page..current_page*per_page-1]
        end
        
        link :next do
          "http://beers/all?page=#{current_page+1}" if current_page < total / per_page
        end
        
        link :prev do
          "http://beers/all?page=#{current_page-1}" if current_page > 1
        end
      end
  
      beers = ["Jever", "Becks", "Eisenbahn", "Colorado"].collect do |name|
        Beer.from_attributes(name: name)
      end
      
      
      list = BeerCollection.new
      list.all_items    = beers # this would be a AR collection from a #find.
      list.current_page = 1
      list.per_page     = 2
      
      assert_equal "{\"beer_collection\":{\"beers\":[{\"name\":\"Jever\",\"links\":[{\"rel\":\"self\",\"href\":\"http://beers/jever\"}]},{\"name\":\"Becks\",\"links\":[{\"rel\":\"self\",\"href\":\"http://beers/becks\"}]}],\"total\":4,\"links\":[{\"rel\":\"next\",\"href\":\"http://beers/all?page=2\"},{\"rel\":\"prev\"}]}}", list.to_json
      
      
      list.current_page = 2
      assert_equal "{\"beer_collection\":{\"beers\":[{\"name\":\"Eisenbahn\",\"links\":[{\"rel\":\"self\",\"href\":\"http://beers/eisenbahn\"}]},{\"name\":\"Colorado\",\"links\":[{\"rel\":\"self\",\"href\":\"http://beers/colorado\"}]}],\"total\":4,\"links\":[{\"rel\":\"next\"},{\"rel\":\"prev\",\"href\":\"http://beers/all?page=1\"}]}}", list.to_json
    end
  end
end
