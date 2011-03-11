require 'test_helper'

require "test_xml/mini_test"
require "roxml"


require "roar/representer/roxml"
require 'roar/model/representable'

class RoxmlRepresenterFunctionalTest < MiniTest::Spec
  class ModelWithItem < TestModel # TODO: use me!
    def item; attributes["item"]; end
    def item=(item); attributes["item"]=item; end
  end
  
  
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
  
  
  
  class TestXmlRepresenter < Roar::Representer::Roxml
    xml_name :test  # FIXME: get from represented?
    has_one :id
    
    self.represented_class= TestModel
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
      @o = TestModel.new(@m)
      @r = TestXmlRepresenter.new(@o)
    end
    
    describe "without options" do
      it "#serialize returns the serialized model" do
        assert_exactly_match_xml "<test><id>1</id></test>", @r.serialize(@o, "application/xml")
      end
      
      it ".from_xml returns the deserialized model" do
        assert_model TestModel.new("id" => "1"), TestXmlRepresenter.deserialize(TestModel, "xml", "<test><id>1</id></test>")
      end
      
      it "#to_xml returns the serialized xml" do
        assert_exactly_match_xml "<test><id>1</id></test>", @r.serialize(@o, "application/xml")
      end
      
    end
    
    
    describe "with a typed attribute" do
      before do
        @c = Class.new(TestXmlRepresenter) do
          xml_accessor :item, :as => Item
        end
        
        @o.instance_eval do
          def item; attributes["item"]; end
          def item=(item); attributes["item"]=item; end
        end
        @r = @c.new(@o)
      end
      
      it "#serialize skips empty :item" do
        assert_exactly_match_xml "<test><id>1</id></test>", @r.serialize(@o, "application/xml")
      end
      
      it "#to_xml delegates to ItemXmlRepresenter#to_xml" do
        @o.item = Item.new("value" => "Bier")
        assert_exactly_match_xml "<test><id>1</id><item><value>Bier</value></item>\n</test>", 
          @r.serialize(@o, "application/xml")
      end
      
      it ".from_xml typecasts :item" do
        @m = @r.class.deserialize(TestModel, "application/xml", "<test><id>1</id><item><value>beer</value></item>\n</test>")
        assert_instance_of TestModel, @m
        assert_equal "1", @m.id
        assert_model Item.new("value" => "beer"), @m.item
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
