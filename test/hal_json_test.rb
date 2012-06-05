require 'test_helper'
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
      assert_equal "{\"links\":{\"self\":{\"href\":\"http://self\"},\"next\":{\"title\":\"Hey, @myabc\",\"href\":\"http://hit\"}}}", @song.to_json
    end
    
    it "parses incoming JSON links correctly" do
      @song.from_json "{\"links\":{\"self\":{\"href\":\"http://self\",\"title\":\"Hey, @myabc\"}}}"
      assert_equal "http://self", @song.links[:self].href
      assert_equal "Hey, @myabc", @song.links[:self].title
      assert_equal nil, @song.links[:next]
    end
  end
  
  
  describe "HAL/JSON" do
    before do
      Bla = Module.new do
        include Roar::Representer::JSON::HAL
        property :value
        link :self do
          "http://items/#{value}"
        end
      end
      
      @order_rep = Module.new do
        include Roar::Representer::JSON::HAL
        property :id
        collection :items, :class => Item, :extend => Bla, :embedded => true
        link :self do
          "http://orders/#{id}"
        end
      end
      
      @order = Order.new(:items => [Item.new(:value => "Beer")], :id => 1).extend(@order_rep)
    end
    
    it "render links and embedded resources according to HAL" do
      assert_equal "{\"id\":1,\"_embedded\":{\"items\":[{\"value\":\"Beer\",\"_links\":{\"self\":{\"href\":\"http://items/Beer\"}}}]},\"_links\":{\"self\":{\"href\":\"http://orders/1\"}}}", @order.to_json
    end
    
    it "parses links and resources following the mighty HAL" do
      @order.from_json("{\"id\":2,\"_embedded\":{\"items\":[{\"value\":\"Coffee\",\"_links\":{\"self\":{\"href\":\"http://items/Coffee\"}}}]},\"_links\":{\"self\":{\"href\":\"http://orders/2\"}}}")
      assert_equal 2, @order.id
      assert_equal "Coffee", @order.items.first.value
      assert_equal "http://items/Coffee", @order.items.first.links[:self].href
      assert_equal "http://orders/2", @order.links[:self].href
    end
    
    it "doesn't require _links and _embedded to be present" do
      @order.from_json("{\"id\":2}")
      assert_equal 2, @order.id
      assert_equal [], @order.items
      assert_equal [], @order.links
    end
  end
end
