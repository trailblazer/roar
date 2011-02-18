require 'test_helper'

require "test_xml/mini_test"
require "roxml"


require "roar/representer/roxml"

class RoxmlRepresenterFunctionalTest < MiniTest::Spec
  
  class Item < TestModel
    def value=(value)
      @attributes[:value] = value
    end
  end
  
  class ItemApplicationXml < Roar::Representer::Roxml
    self.represented_class = Item
    
    xml_accessor :value
  end
  
  class TestXmlRepresenter < Roar::Representer::Roxml
    xml_name :test  # FIXME: get from represented?
    has_one :id
    
    self.represented_class= TestModel
  end
  
  describe "RoxmlRepresenter" do
    before do
      @m = {"id" => "1"}
      @o = TestModel.new(@m)
      @r = TestXmlRepresenter.new(@o)
    end
    
    describe "without options" do
      it "#serialize returns the serialized model" do
        assert_exactly_match_xml "<test><id>1</id></test>", @r.serialize(@m)
      end
      
      it ".from_xml returns the deserialized model" do
        assert_equal TestModel.new("id" => "1"), @r.class.from_xml("<test><id>1</id></test>")
      end
      
      it "#to_xml returns the serialized xml" do
        assert_exactly_match_xml "<test><id>1</id></test>", @r.serialize(@m)
      end
      
    end
    
    
    describe "has_one" do
      before do
        @c = Class.new(TestXmlRepresenter) do
          has_one :item, :class => Item
        end
        
        @o.instance_eval do
          def item; attributes[:item]; end
          def item=(item); attributes[:item]=item; end
        end
        @r = @c.new(@o)
      end
      
      it "#to_xml skips empty :item" do
        assert_exactly_match_xml "<test><id>1</id></test>", @r.to_xml.serialize
      end
      
      it "#to_xml delegates to ItemXmlRepresenter#to_xml" do
        @o.item = Item.new(:value => "Bier")
        assert_exactly_match_xml "<test><id>1</id><item><value>Bier</value></item>\n</test>", @r.to_xml.serialize
      end
      
      it ".from_xml typecasts :item" do
        m = @r.class.from_xml("<test><id>1</id><item><value>beer</value></item>\n</test>")
        assert_equal(TestModel.new("id" => "1", "item" => Item.new(:value => "beer")), m)
      end
      
    end
  end
end
