require 'test_helper'

require "test_xml/mini_test"
require "roxml"


require "roar/representer/roxml"

class RoxmlRepresenterFunctionalTest < MiniTest::Spec
  class ItemApplicationXml < Roar::Representer::Roxml
    xml_name :item
    xml_accessor :value
  end
  
  class Item
    include Roar::Model
    accessors :value
    
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
  
  
  describe "with ModelWrapper" do
    class OrderXmlRepresenter < Roar::Representer::Roxml
      xml_accessor :id
      xml_accessor :item, :as => ItemApplicationXml
    end
    
    before do
      @c = Class.new(OrderXmlRepresenter)
    end
    
    
    it "#for_model copies represented model attributes, nothing more" do
      @o = Order.new("id" => 1, "item" => Item.new("value" => "Beer"))
      
      @r = @c.for_model(@o)
      assert_kind_of OrderXmlRepresenter, @r
      assert_equal 1, @r.id
      
      @i = @r.item
      assert_kind_of ItemApplicationXml, @i
      assert_equal "Beer", @i.value
    end
    
    it "Model::ActiveRecordMethods#to_nested_attributes" do
      @o = Order.new("id" => 1, "item" => Item.new("value" => "Beer"))
      @r = @c.for_model(@o)
      
      @c.class_eval do
        include Roar::Representer::ActiveRecordMethods
      end
      assert_equal({"id" => 1, "item_attributes" => {"value" => "Beer"}}, @r.to_nested_attributes) # DISCUSS: overwrite #to_attributes.
    end
    
  end
  
  
  
  
  
  class TestXmlRepresenter < Roar::Representer::Roxml
    xml_name :order  # FIXME: get from represented?
    xml_accessor :id
  end
  
  
  describe "RoxmlRepresenter" do
    before do
      @m = {"id" => "1"}
      @o = Order.new(@m)
      @r = TestXmlRepresenter.new
      @i = ItemApplicationXml.new
      @i.value = "Beer"
    end
    
    describe "#for_attributes" do
      it "#for_attributes copies represented attributes, nothing more" do
        @r = OrderXmlRepresenter.for_attributes("id" => 1, "item" => @i)
        assert_kind_of OrderXmlRepresenter, @r
        assert_equal 1, @r.id
        
        assert_kind_of ItemApplicationXml, @r.item
        assert_equal @r.item.value, "Beer"
      end
    end
    
    
    describe "#to_attributes" do
      it "returns a nested attributes hash" do
        @r = OrderXmlRepresenter.for_attributes("id" => 1, "item" => @i)
        assert_equal({"id" => 1, "item" => {"value" => "Beer"}}, @r.to_attributes)
      end
      
      it "calls definition :to_attributes block" do
        class Representer < Roar::Representer::Roxml
          xml_accessor :id, :to_attributes => Proc.new { |attrs| attrs["id"] += 1 }
        end
        
        @r = Representer.for_attributes("id" => 1)
        assert_equal({"id" => 2}, @r.to_attributes)
      end
      
    end
    
    
    describe "#to_xml" do
      it "serializes the current model" do
        assert_exactly_match_xml "<order/>", @r.to_xml.serialize
        
        @r.id = 2
        assert_exactly_match_xml "<rap><id>2</id></rap>", @r.to_xml(:name => :rap).serialize
      end
    end
    
    
    describe "without options" do
      it "#serialize_model returns the serialized model" do
        assert_exactly_match_xml "<order><id>1</id></order>", @r.class.serialize_model(@o)
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
        @c = Class.new(Roar::Representer::Roxml) do
          xml_name :order
          xml_accessor :id
          xml_accessor :item, :as => ItemApplicationXml
        end
      end
      
      it "#serialize_model skips empty :item" do
        assert_exactly_match_xml "<order><id>1</id></order>", @c.serialize_model(@o)
      end
      
      it "#to_xml delegates to ItemXmlRepresenter#to_xml" do
        @o.item = Item.new("value" => "Bier")
        assert_exactly_match_xml "<order><id>1</id><item><value>Bier</value></item>\n</order>", 
          @c.serialize_model(@o)
      end
      
      it ".from_xml typecasts :item" do
        @m = @c.deserialize("<order><id>1</id><item><value>beer</value></item>\n</order>")
        
        assert_equal "1",     @m.id
        assert_equal "beer",  @m.item.value
      end
    end
    
    
    describe "with a typed list" do
      before do
        @c = Class.new(Roar::Representer::Roxml) do
          xml_name :order
          xml_accessor :id
          xml_accessor :items, :as => [ItemApplicationXml], :tag => :item
        end
        
        @o = GreedyOrder.new("id" => 1)
      end
      
      it "#serialize_model skips empty :item" do
        assert_exactly_match_xml "<order><id>1</id></order>", @c.serialize_model(@o)
      end
      
      it "#serialize delegates to ItemXmlRepresenter#to_xml in list" do
        @o.items = [Item.new("value" => "Bier")]
        
        assert_exactly_match_xml "<order><id>1</id><item><value>Bier</value></item></order>", 
          @c.serialize_model(@o)
      end
      
      it ".from_xml typecasts list" do
        @m = @c.deserialize("<order><id>1</id><item><value>beer</value></item>\n</order>")
        
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
