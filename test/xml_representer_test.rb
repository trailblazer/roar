require 'test_helper'

class ItemRepresenter
  include Roar::Representer::XML
  self.representation_wrap= :item
  property :value
end

class PositionRepresenter
  include Roar::Representer::XML
  self.representation_wrap= :position
  property :id
  property :item, :as => ItemRepresenter
end




class XMLRepresenterUnitTest < MiniTest::Spec
  describe "XmlRepresenter" do
    describe "#link" do
      class Rapper
        include Roar::Representer::XML
        include Roar::Representer::Feature::Hypermedia
        
        link :self
        link :next
      end
      
      it "creates a LinksDefinition" do
        assert_equal 1, Rapper.representable_attrs.size
        assert_equal [{:rel=>:self, :block=>nil}, {:rel=>:next, :block=>nil}], Rapper.representable_attrs.first.rel2block
      end
    end
  end
end


class XMLRepresenterFunctionalTest < MiniTest::Spec
  class GreedyOrder
    include TestModel
    accessors :id, :items
    
    def self.model_name
      :order
    end
  end
  
  class TestXmlRepresenter
    include Roar::Representer::XML
    self.representation_wrap= :order  # FIXME: get from represented?
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
    
    describe "#to_attributes" do
      it "returns a nested attributes hash" do
        @r = PositionRepresenter.from_attributes("id" => 1, "item" => @i)
        assert_equal({"id" => 1, "item" => {"value" => "Beer"}}, @r.to_attributes)
      end
    end
    
    
    describe "#to_xml" do
      it "serializes the current model" do
        assert_xml_equal "<order/>", @r.to_xml
        
        @r.id = 2
        assert_xml_equal "<rap><id>2</id></rap>", @r.to_xml(:name => :rap)
      end
      
      it "is aliased to #serialize" do
        assert_equal @r.to_xml, @r.serialize
      end
    end
    
    describe "#from_xml" do
      class Order
        include Roar::Representer::XML
        property :id
        property :pending
      end
    
      it "is aliased to #deserialize" do
        assert_equal TestXmlRepresenter.from_xml("<order/>").to_attributes, TestXmlRepresenter.deserialize("<order/>").to_attributes
      end
      
      it "accepts :except option" do
        order = Order.from_xml(%{<order><id>1</id><pending>1</pending></order>}, :except => [:id])
        assert_equal nil, order.id
        assert_equal "1", order.pending
      end
      
      it "accepts :include option" do
        order = Order.from_xml(%{<order><id>1</id><pending>1</pending></order>}, :include => [:id])
        assert_equal "1", order.id
        assert_equal nil, order.pending
      end
    end
    
    
    describe "without options" do
      it "#to_xml returns the serialized model" do
        @r.id = 1
        assert_xml_equal "<order><id>1</id></order>", @r.to_xml
      end
      
      
      it ".from_xml returns the deserialized model" do
        @m = TestXmlRepresenter.from_xml("<order><id>1</id></order>")
        assert_equal "1", @m.id
      end
      
      #it ".from_xml still works with nil" do
      #  assert TestXmlRepresenter.from_xml(nil)
      #end
      
    end
    
    
    describe "with a typed attribute" do
      before do
        @r = PositionRepresenter.from_attributes("id" => "1")
      end
      
      it "#serialize skips empty :item" do
        assert_xml_equal "<position><id>1</id></position>", @r.to_xml
      end
      
      it "#to_xml delegates to ItemRepresenter#to_xml" do
        @r.item = @i
        assert_xml_equal "<position><id>1</id><item><value>Beer</value></item></position>", @r.to_xml
      end
      
      it ".from_xml typecasts :item" do
        @m = PositionRepresenter.from_xml("<position><id>1</id><item><value>beer</value></item>\n</position>")
        
        assert_equal "1",     @m.id
        assert_equal "beer",  @m.item.value
      end
    end
    
    
    describe "with a typed list" do
      before do
        @c = Class.new do
          include Roar::Representer::XML
          
          self.representation_wrap= :order
          property :id
          collection :items, :as => ItemRepresenter, :from => :item
        end
        
        @r = @c.from_attributes("id" => 1)
      end
      
      it "#serialize_model skips empty :item" do
        assert_xml_equal "<order><id>1</id></order>", @r.to_xml
      end
      
      it "#serialize delegates to ItemXmlRepresenter#to_xml in list" do
        @r.items = [ItemRepresenter.from_attributes("value" => "Bier")]
        
        assert_xml_equal "<order><id>1</id><item><value>Bier</value></item></order>", 
          @r.to_xml
      end
      
      it ".from_xml typecasts list" do
        @m = @c.from_xml("<order><id>1</id><item><value>beer</value></item>\n</order>")
        
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
      assert_equal :link, @l.class.representation_wrap
    end
    
    
    it "responds to #rel" do
      assert_equal "self", @l.rel
    end
    
    it "responds to #href" do
      assert_equal "http://roar.apotomo.de", @l.href
    end
  end
end
