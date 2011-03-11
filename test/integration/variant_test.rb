require 'test_helper'

require "test_xml/mini_test"
require "roxml"


require "roar/representer/roxml"
require "roar/model/representable"

class VariantFunctionalTest < MiniTest::Spec
  class VariantXmlRepresenter < Roar::Representer::Roxml
    xml_accessor :size
    xml_accessor :id
    xml_accessor :title
    xml_accessor :price
  end
  
  class Variant
    include Roar::Model
    accessors :size, :price, :id, :title
    
    
    include Roar::Model::Representable
    represents "application/xml", :with => VariantXmlRepresenter
    
  end
  
  # from(app/xml, <variant>..</variant>)
  # to(app/xml)
  
  
  
  describe "VariantXmlRepresenter" do
    before do
      @shirt = Variant.new("size" => "S", "price" => "9.99", "id" => "1", "title" => "China Shirt")
    end
  
    it "be deserializable" do
      @v = Variant.from("application/xml", "<variant><id>1</id><size>S</size><price>9.99</price><title>China Shirt</title><variant>")
      assert_model @shirt, @v
    end
    
    it "be serializable" do
      assert_exactly_match_xml "<variant><id>1</id><size>S</size><price>9.99</price><title>China Shirt</title><variant>", @shirt.to_xml
    end
    
  end
  
end
