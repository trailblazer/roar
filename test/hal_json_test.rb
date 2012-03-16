require 'test_helper'

require "roar/representer/json"
require 'roar/representer/json/hal'

class HalJsonTest < MiniTest::Spec
  module SongRepresenter
    include Roar::Representer::JSON
    include Roar::Representer::JSON::HAL::Links
    
    link :self do
      "http://self"
    end
    
    link :next do
      "http://hit"
    end
  end
  
  describe "JSON::HAL::Links" do
    before do
      @song = Object.new.extend(SongRepresenter)
    end
    
    it "renders links plain with the links key" do
      assert_equal "{\"links\":{\"self\":\"http://self\",\"next\":\"http://hit\"}}", @song.to_json
    end
    
    it "parses incoming JSON links correctly" do
      @song.from_json "{\"links\":{\"self\":\"http://self\"}}"
      assert_equal "http://self", @song.links[:self]
      assert_equal nil, @song.links[:next]
    end
  end
  
  module OrderRepresenter
    include Roar::Representer::JSON::HAL
    
    property :id
    collection :items, :class => Item, :extend => SongRepresenter, :embedded => true
    
    link :self do
      "http://orders/#{id}"
    end
  end
  
  describe "HAL/JSON" do
    before do
      @order = Order.new(:items => [Item.new], :id => 1).extend(OrderRepresenter)
    end
    
    it "render links" do
      assert_equal "{\"id\":1,\"items\":[],\"_links\":{\"self\":\"http://orders/1\"}}", Order.new(:id => 1).extend(OrderRepresenter).to_json
    end
  end
end
