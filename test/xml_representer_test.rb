require 'test_helper'

class Order
  include Roar::Model
  accessors :id, :item
  
  def self.model_name
    :order
  end
end


class ItemRepresenter
  include Roar::Representer::XML
  self.representation_name= :item
  property :value
end

class PositionRepresenter
  include Roar::Representer::XML
  self.representation_name= :position
  property :id
  property :item, :as => ItemRepresenter
end




class XMLRepresenterUnitTest < MiniTest::Spec
  describe "XmlRepresenter" do
    describe "#link" do
      class Rapper
        include Roar::Representer::XML
        link :self
        link :next
      end
      
      it "creates a LinksDefinition" do
        assert_equal 1, Rapper.representable_attrs.size
        assert_equal [{:rel=>:self, :block=>nil}, {:rel=>:next, :block=>nil}], Rapper.representable_attrs.first.rel2block
      end
    end
    
    describe "#from_attributes" do
      it "accepts a block" do
        @c = Class.new do
          include Roar::Representer::XML
          
          attr_accessor :name
        end
        
        assert_equal("Conan", @c.from_attributes({}) { |rep| rep.name = "Conan" }.name)
      end
    end
  end
end

class LinksDefinitionTest < MiniTest::Spec
  describe "LinksDefinition" do
    before do
      @d = Roar::Representer::LinksDefinition.new(:links)
    end
    
    it "accepts options in constructor" do
      assert_equal [], @d.rel2block
    end
    
    it "accepts configuration" do
      @d.rel2block << {:rel => :self}
      assert_equal [{:rel=>:self}], @d.rel2block
    end
  end
end

class XMLDefinitionTest < MiniTest::Spec
  class Rapper
    attr_accessor :name
  end
  
  describe "ROXML::Definition" do
    it "responds to #populate" do
      @r = Rapper.new
      Representable::Definition.new(:name).populate(@r, "name" => "Eugen")
      assert_equal "Eugen", @r.name
    end
  end
end





class XMLRepresenterFunctionalTest < MiniTest::Spec
  class GreedyOrder
    include Roar::Model
    accessors :id, :items
    
    def self.model_name
      :order
    end
  end
  
  class TestXmlRepresenter
    include Roar::Representer::XML
    self.representation_name= :order  # FIXME: get from represented?
    property :id
  end
  
  
  describe "XMLRepresenter" do
    before do
      @m = {"id" => "1"}
      @o = Order.new(@m)
      @r = TestXmlRepresenter.new
      @i = ItemRepresenter.new
      @i.value = "Beer"
    end
    
    describe "#from_attributes" do
      it "copies represented attributes, only" do
        @r = PositionRepresenter.from_attributes("id" => 1, "item" => @i, "unknown" => 1)
        assert_kind_of PositionRepresenter, @r
        assert_equal 1, @r.id
        
        assert_kind_of ItemRepresenter, @r.item
        assert_equal @r.item.value, "Beer"
      end
    end
    
    
    describe "#to_attributes" do
      it "returns a nested attributes hash" do
        @r = PositionRepresenter.from_attributes("id" => 1, "item" => @i)
        assert_equal({"id" => 1, "item" => {"value" => "Beer"}}, @r.to_attributes)
      end
    end
    
    
    describe "#to_xml" do
      it "serializes the current model" do
        assert_xml_equal "<order/>", @r.to_xml.serialize
        
        @r.id = 2
        assert_xml_equal "<rap><id>2</id></rap>", @r.to_xml(:name => :rap).serialize
      end
    end
    
    
    describe "without options" do
      it "#serialize returns the serialized model" do
        @r.id = 1
        assert_xml_equal "<order><id>1</id></order>", @r.serialize
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
        @r = PositionRepresenter.from_attributes("id" => "1")
      end
      
      it "#serialize skips empty :item" do
        assert_xml_equal "<position><id>1</id></position>", @r.serialize
      end
      
      it "#to_xml delegates to ItemRepresenter#to_xml" do
        @r.item = @i
        assert_xml_equal "<position><id>1</id><item><value>Beer</value></item></position>", @r.serialize
      end
      
      it ".from_xml typecasts :item" do
        @m = PositionRepresenter.deserialize("<position><id>1</id><item><value>beer</value></item>\n</position>")
        
        assert_equal "1",     @m.id
        assert_equal "beer",  @m.item.value
      end
    end
    
    
    describe "with a typed list" do
      before do
        @c = Class.new do
          include Roar::Representer::XML
          
          self.representation_name= :order
          property :id
          collection :items, :as => ItemRepresenter, :tag => :item
        end
        
        @r = @c.from_attributes("id" => 1)
      end
      
      it "#serialize_model skips empty :item" do
        assert_xml_equal "<order><id>1</id></order>", @r.serialize
      end
      
      it "#serialize delegates to ItemXmlRepresenter#to_xml in list" do
        @r.items = [ItemRepresenter.from_attributes("value" => "Bier")]
        
        assert_xml_equal "<order><id>1</id><item><value>Bier</value></item></order>", 
          @r.serialize
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

class XmlHyperlinkRepresenterTest < MiniTest::Spec
  describe "API" do
    before do
      @l = Roar::Representer::XML::Hyperlink.from_xml(%{<link rel="self" href="http://roar.apotomo.de"/>})
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
