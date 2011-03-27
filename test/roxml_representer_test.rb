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
  
  class GreedyOrder
    include Roar::Model
    accessors :id, :items
    
    def self.model_name
      :order
    end
  end
  
  
  
  class TestXmlRepresenter < Roar::Representer::Roxml
    xml_name :test  # FIXME: get from represented?
    has_one :id
  end
  
  
  describe "RoxmlRepresenter" do
    before do
      @m = {"id" => "1"}
      @o = Order.new(@m)
      @r = TestXmlRepresenter.new
    end
    
    describe "without options" do
      it "#serialize_model returns the serialized model" do
        assert_exactly_match_xml "<order><id>1</id></order>", @r.serialize(@o)
      end
      
      it ".from_xml returns the deserialized model" do
        @m = TestXmlRepresenter.deserialize("<order><id>1</id></order>")
        assert_equal "1", @m.id
      end
      
      it ".from_xml still works with nil" do
        assert TestXmlRepresenter.deserialize(nil)
      end
      
    end
    
    
    describe "with a typed attribute" do
      before do
        @c = Class.new(TestXmlRepresenter) do
          xml_accessor :item, :as => ItemApplicationXml
        end
        
        @r = @c.new(@o)
      end
      
      it "#serialize skips empty :item" do
        assert_exactly_match_xml "<order><id>1</id></order>", @r.serialize(@o)
      end
      
      it "#to_xml delegates to ItemXmlRepresenter#to_xml" do
        @o.item = Item.new("value" => "Bier")
        assert_exactly_match_xml "<order><id>1</id><item><value>Bier</value></item>\n</order>", 
          @r.serialize(@o)
      end
      
      it ".from_xml typecasts :item" do
        @m = @r.class.deserialize("<order><id>1</id><item><value>beer</value></item>\n</order>")
        
        assert_equal "1",     @m.id
        assert_equal "beer",  @m.item.value
      end
    end
    
    
    describe "with a typed list" do
      before do
        @c = Class.new(TestXmlRepresenter) do
          xml_accessor :items, :as => [ItemApplicationXml], :tag => :item
        end
        
        @o = GreedyOrder.new("id" => 1)
        @r = @c.new
      end
      
      it "#serialize skips empty :item" do
        assert_exactly_match_xml "<order><id>1</id></order>", @r.serialize(@o)
      end
      
      it "#to_xml delegates to ItemXmlRepresenter#to_xml in list" do
        @o.items = [Item.new("value" => "Bier")]
        
        assert_exactly_match_xml "<order><id>1</id><item><value>Bier</value></item>\n</order>", 
          @r.serialize(@o)
      end
      
      it ".from_xml typecasts list" do
        @m = @r.class.deserialize("<order><id>1</id><item><value>beer</value></item>\n</order>")
        
        assert_equal "1",     @m.id
        assert_equal 1,       @m.items.size
        assert_equal "beer",  @m.items.first.value
      end
    end
    
  end
end

class HyperlinkRepresenterUnitTest
  describe "API" do
    before do
      @l = Roar::Representer::Roxml::Hyperlink.from_xml(%{<link rel="self" href="http://roar.apotomo.de"/>})
    end
    
    it "responds to #rel" do
      assert_equal "self", @l.rel
    end
    
    it "responds to #href" do
      assert_equal "http://roar.apotomo.de", @l.href
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
      #assert_equal Hash, @c.roxml_attrs.first.sought_type
    end
    
    it "raises an exception if no representer class is found" do
      @c.mime_type = "text/html"
      
      assert_raises RuntimeError do
        @c.has_one :id, :class => Item  # asking Item for "text/html" representer fails.
      end
    end
  end
end
