require 'test_helper'

require "test_xml/mini_test"
require "roar/representer/json"

class JsonRepresenterTest < MiniTest::Spec
  class Order
    include Roar::Representer::JSON
    property :id
    property :pending
  end
  
  
  describe "JsonRepresenter" do
    before do
      @order = Order.new
    end
    
    
    describe "#to_json" do
      before do
        @order.id = 1
      end
      
      it "returns the serialized model" do
        assert_equal '{"id":1}', @order.to_json
      end
      
      it "is aliased by #serialize" do
        assert_equal '{"id":1}', @order.serialize
      end
    end
    
    describe "#from_json" do
      it "returns the deserialized model" do
        @order.from_json('{"id":1}')
        assert_equal 1, @order.id
      end
      
      it "is aliased by #deserialize" do
        @order.deserialize('{"id":1}')
        assert_equal 1, @order.id
      end
      
      it "works with a nil document" do
        assert @order.from_json(nil)
      end
    end
    
    describe "JSON.from_json" do
      it "is aliased by #deserialize" do
        @order = Order.deserialize('{"id":1}')
        assert_equal 1, @order.id
      end
    end
  end
end

class JsonHyperlinkRepresenterTest
  describe "API" do
    before do
      @l = Roar::Representer::JSON::Hyperlink.from_json({:rel => :self, :href => "http://roar.apotomo.de"}.to_json)
    end
    
    it "responds to #rel" do
      assert_equal "self", @l.rel
    end
    
    it "responds to #href" do
      assert_equal "http://roar.apotomo.de", @l.href
    end
  end
end

class JsonHypermediaTest
  describe "Hypermedia API" do
    before do
      @c = Class.new do
        include AttributesContructor
        include Roar::Representer::JSON
        include Roar::Representer::Feature::Hypermedia
        
        property :id
        
        link :self do "http://self" end
        link :next do "http://next/#{id}" end
      end
      
      @r = @c.new
    end
    
    it "responds to #links" do
      assert_equal [], @r.links
    end
    
    it "extracts links from JSON" do
      @r = @c.from_json({:links => [{:rel => "self", :href => "http://self"}]}.to_json)
      
      assert_equal 1, @r.links.size
      assert_equal(["self", "http://self"], [@r.links.first.rel, @r.links.first.href]) 
    end
    
    it "renders link: correctly in JSON" do
      assert_equal "{\"id\":1,\"links\":[{\"rel\":\"self\",\"href\":\"http://self\"},{\"rel\":\"next\",\"href\":\"http://next/1\"}]}", @c.new(:id => 1).to_json
    end
  end
end

