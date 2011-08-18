require File.expand_path(File.dirname(__FILE__) + '/test_helper')

require "test_xml/mini_test"
require "roar/representer/json"

class JsonRepresenterFunctionalTest < MiniTest::Spec
  class OrderRepresenter < Roar::Representer::JSON
    self.representation_name= :order
    representable_property :id
  end
  
  
  describe "JsonRepresenter" do
    before do
      @r = OrderRepresenter.new
    end
    
    describe "#to_json" do
      it "#serialize returns the serialized model" do
        @r.id = 1
        assert_equal '{"order":{"id":1}}', @r.serialize
      end
      
      
      it ".from_xml returns the deserialized model" do
        @m = OrderRepresenter.deserialize('{"order": {"id":1}}')
        assert_equal 1, @m.id
      end
      
      it ".from_xml still works with nil" do
        assert OrderRepresenter.deserialize(nil)
      end
      
    end
  end
  
end

class JsonHyperlinkRepresenterTest
  describe "API" do
    before do
      @l = Roar::Representer::JSON::Hyperlink.from_json({:link => {:rel => :self, :href => "http://roar.apotomo.de"}}.to_json)
    end
    
    it "responds to #representation_name" do
      assert_equal :link, @l.class.representation_name
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
      @c = Class.new(Roar::Representer::JSON) do
        include Roar::Representer::Feature::Hypermedia
        
        self.representation_name= :order
        
        representable_property :id
        
        link :self do "http://self" end
        link :next do "http://next/#{id}" end
      end
      
      @r = @c.new
    end
    
    it "responds to #links" do
      assert_equal nil, @r.links
    end
    
    it "computes links in #from_attributes" do
      @r = @c.from_attributes({"id" => 1})
      assert_equal 2, @r.links.size
      assert_equal({"rel"=>:self, "href"=>"http://self"}, @r.links.first.to_attributes)
      assert_equal({"rel"=>:next, "href"=>"http://next/1"}, @r.links.last.to_attributes) 
    end
    
    it "extracts links from JSON" do
      @r = @c.deserialize({:order => {:links => [{:rel => "self", :href => "http://self"}]}}.to_json)
      
      assert_equal 1, @r.links.size
      assert_equal({"rel"=>"self", "href"=>"http://self"}, @r.links.first.to_attributes) 
    end
    
    it "renders link: correctly in JSON" do
      assert_equal "{\"order\":{\"id\":1,\"links\":[{\"rel\":\"self\",\"href\":\"http://self\"},{\"rel\":\"next\",\"href\":\"http://next/1\"}]}}", @c.from_attributes({"id" => 1}).serialize
    end
    
  end
end

