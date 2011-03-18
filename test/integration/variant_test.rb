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
    def self.model_name
      "variant"
    end
    
    include Roar::Model
    accessors :size, :price, :id, :title
    
    
    include Roar::Model::Representable
    represents "application/xml", :with => VariantXmlRepresenter
  end
  
  
  class ArticleXmlRepresenter < Roar::Representer::Roxml
    xml_accessor :id
    xml_accessor :variants, :as => [Variant], :tag => :variant
  end
  
  
  class Article
    def self.model_name
      "article"
    end
    
    include Roar::Model
    accessors :id, :variants
    
    
    include Roar::Model::Representable
    represents "application/xml", :with => ArticleXmlRepresenter
  end
  
  
  describe "All models in this use-case" do
  describe "VariantXmlRepresenter" do
    before do
      @shirt = Variant.new("size" => "S", "price" => "9.99", "id" => "1", "title" => "China Shirt")
    end
  
    it "be deserializable" do
      @v = Variant.from("application/xml", "<variant><id>1</id><size>S</size><price>9.99</price><title>China Shirt</title><variant>")
      assert_model @shirt, @v
    end
    
    it "be serializable" do
      # assert_xml_match (no ordering)
      assert_match_xml "<variant><size>S</size><id>1</id><title>China Shirt</title><price>9.99</price><variant>", @shirt.to("application/xml")
    end
  end
  
  
  # Article has Variants
  describe "ArticleXmlRepresenter" do
    before do
      @china_s  = Variant.new("size" => "S", "price" => "9.99", "id" => "1-s", "title" => "China Shirt-S")
      @china_m  = Variant.new("size" => "M", "price" => "9.99", "id" => "1-m", "title" => "China Shirt-M")
      @shirt    = Article.new("id" => 1, "variants" => [@china_s, @china_m])
    end
    
    it "deserializes" do
      @a = Article.from("application/xml", "<article>
        <id>1</id>
        <variant><size>S</size><id>1-s</id><title>China Shirt-S</title><price>9.99</price></variant>
        <variant><size>M</size><id>1-m</id><title>China Shirt-M</title><price>9.99</price></variant>
      <article>")
      puts @a.inspect
      assert_model @shirt, @a
    end
    
  end
  
  end
end
