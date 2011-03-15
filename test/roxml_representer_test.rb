require 'test_helper'

require "test_xml/mini_test"
require "roxml"


require "roar/representer/roxml"
require 'roar/model/representable'

class RoxmlRepresenterFunctionalTest < MiniTest::Spec
  class ItemApplicationXml < Roar::Representer::Roxml
    xml_accessor :value
  end
  
  class Item
    include Roar::Model
    accessors :value
    
    include Roar::Model::Representable
    represents "application/xml", :with => ItemApplicationXml
    
    def self.model_name
      "item"
    end
  end
  
  class Order
    include Roar::Model
    accessors :id, :item
    
    def self.model_name
      :order
    end
  end
  
  
  
  class TestXmlRepresenter < Roar::Representer::Roxml
    xml_name :test  # FIXME: get from represented?
    has_one :id
    
    #self.represented_class= TestModel
  end
  
  describe "Item" do
    it "responds to #to" do
      assert_exactly_match_xml "<item><value>Song</value></item>", 
        Item.new("value" => "Song").to("application/xml")
    end
  end
  
  describe "RoxmlRepresenter" do
    before do
      @m = {"id" => "1"}
      @o = Order.new(@m)
      @r = TestXmlRepresenter.new(@o)
    end
    
    describe "without options" do
      it "#serialize returns the serialized model" do
        assert_exactly_match_xml "<order><id>1</id></order>", @r.serialize(@o, "application/xml")
      end
      
      it ".from_xml returns the deserialized model" do
        assert_model @o, TestXmlRepresenter.deserialize(Order, "xml", "<order><id>1</id></order>")
      end
      
      it "#to_xml returns the serialized xml" do
        assert_exactly_match_xml "<order><id>1</id></order>", @r.serialize(@o, "application/xml")
      end
      
    end
    
    
    describe "with a typed attribute" do
      before do
        @c = Class.new(TestXmlRepresenter) do
          xml_accessor :item, :as => Item
        end
        
        @r = @c.new(@o)
      end
      
      it "#serialize skips empty :item" do
        assert_exactly_match_xml "<order><id>1</id></order>", @r.serialize(@o, "application/xml")
      end
      
      it "#to_xml delegates to ItemXmlRepresenter#to_xml" do
        @o.item = Item.new("value" => "Bier")
        assert_exactly_match_xml "<order><id>1</id><item><value>Bier</value></item>\n</order>", 
          @r.serialize(@o, "application/xml")
      end
      
      it ".from_xml typecasts :item" do
        @m = @r.class.deserialize(Order, "application/xml", "<order><id>1</id><item><value>beer</value></item>\n</order>")
        
        assert_model Order.new("id" => 1, "item" => Item.new("value" => "beer")), @m
      end
    end
  
  end
end


require "roar/model/representable"
class RoxmlRepresenterUnitTest
  class Item
    include Roar::Model::Representable
    
    represents "application/xml", :with => Hash
  end
  
  describe "has_one" do
    before do
      @c = Class.new(Roar::Representer::Roxml) do
        self.mime_type= "application/xml"
        has_one :item, :class => Item
      end
    end
    
    it "saves the representer class" do
      assert_equal Hash, @c.roxml_attrs.first.sought_type
    end
    
    it "raises an exception if no representer class is found" do
      @c.mime_type = "text/html"
      
      assert_raises RuntimeError do
        @c.has_one :id, :class => Item  # asking Item for "text/html" representer fails.
      end
    end
  end
end
