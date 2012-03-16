require 'roar/representer/json/hal'

class HalJsonTest < MiniTest::Spec
  module SongRepresenter
    include Roar::Representer::JSON
    include Roar::Representer::JSON::HAL::Links
    
    link :self do
      "http://self"
    end
    
    link :rel => :next, :title => "Hey, @myabc" do
      "http://hit"
    end
  end
  
  describe "JSON::HAL::Links" do
    before do
      @song = Object.new.extend(SongRepresenter)
    end
    
    it "renders links according to the HAL spec" do
      assert_equal "{\"links\":{\"self\":{\"href\":\"http://self\"},\"next\":{\"href\":\"http://hit\",\"title\":\"Hey, @myabc\"}}}", @song.to_json
    end
    
    it "parses incoming JSON links correctly" do
      @song.from_json "{\"links\":{\"self\":{\"href\":\"http://self\",\"title\":\"Hey, @myabc\"}}}"
      assert_equal "http://self", @song.links[:self].href
      assert_equal "Hey, @myabc", @song.links[:self].title
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
      assert_equal "{\"id\":1,\"_links\":{\"self\":\"http://orders/1\"}}", Order.new(:id => 1).extend(OrderRepresenter).to_json
    end
  end
end
