require 'test_helper'

class ItemRepresenter
  include AttributesContructor
  include Roar::Representer::XML
  self.representation_wrap= :item
  property :value
  attr_accessor :value
end

class PositionRepresenter
  include AttributesContructor
  include Roar::Representer::XML
  self.representation_wrap= :position
  property :id
  property :item, :class => ItemRepresenter
  attr_accessor :id, :item
end


class XMLRepresenterFunctionalTest < MiniTest::Spec
  class Order
    include AttributesContructor
    attr_accessor :id, :items
  end
  
  class GreedyOrder < Order
  end
  
  class TestXmlRepresenter
    include Roar::Representer::XML
    self.representation_wrap= :order
    property :id
    attr_accessor :id
  end
  
  
  describe "XMLRepresenter" do
    before do
      @m = {"id" => "1"}
      @o = Order.new(@m)
      
      @r = TestXmlRepresenter.new
      @i = ItemRepresenter.new
      @i.value = "Beer"
    end
    
    describe "#to_xml" do
      it "serializes the model" do
        assert_xml_equal "<order/>", @r.to_xml
        
        @r.id = 1
        assert_xml_equal "<order><id>1</id></order>", @r.to_xml
        
        @r.id = 2
        assert_xml_equal "<rap><id>2</id></rap>", @r.to_xml(:wrap => :rap)
      end
      
      it "is aliased by #serialize" do
        assert_equal @r.to_xml, @r.serialize
      end
      
      it "accepts :include and :exclude" do
        assert_equal '<order/>', @r.to_xml(:exclude => [:id])
      end
    end
    
    describe "#from_xml" do
      it "deserializes object" do
        @order = Order.new.from_xml("<order><id>1</id></order>")
        assert_equal "1", @order.id
      end
      
      it "is aliased by #deserialize" do
        @order = Order.new.deserialize("<order><id>1</id></order>")
        assert_equal "1", @order.id
      end
      
      it "accepts :include and :exclude" do
        @order = Order.new.deserialize("<order><id>1</id></order>", :exclude => [:id])
        assert_equal nil, @order.id
      end
    end
    
    
    describe "XML.from_xml" do
      class Order
        include Roar::Representer::XML
        property :id
        property :pending
        attr_accessor :id, :pending
      end
    
      it "is aliased to #deserialize" do
        assert_equal TestXmlRepresenter.from_xml("<order/>").id, TestXmlRepresenter.deserialize("<order/>").id
      end
      
      it "accepts :exclude option" do
        order = Order.from_xml(%{<order><id>1</id><pending>1</pending></order>}, :exclude => [:id])
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
        @r = PositionRepresenter.new("id" => "1")
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
          include AttributesContructor
          include Roar::Representer::XML
          
          self.representation_wrap= :order
          property :id
          collection :items, :class => ItemRepresenter, :from => :item
          attr_accessor :id, :items
        end
        
        @r = @c.new("id" => 1)
      end
      
      it "#serialize_model skips empty :item" do
        assert_xml_equal "<order><id>1</id></order>", @r.to_xml
      end
      
      it "#serialize delegates to ItemXmlRepresenter#to_xml in list" do
        @r.items = [ItemRepresenter.new("value" => "Bier")]
        
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
      @link = Roar::Representer::Feature::Hypermedia::Hyperlink.new.extend(Roar::Representer::XML::HyperlinkRepresenter).from_xml(%{<link rel="self" href="http://roar.apotomo.de" media="web"/>})
    end
    
    it "responds to #rel" do
      assert_equal "self", @link.rel
    end
    
    it "responds to #href" do
      assert_equal "http://roar.apotomo.de", @link.href
    end
    
    it "responds to #media" do
      assert_equal "web", @link.media
    end
    
    it "responds to #to_xml" do
      assert_xml_equal %{<link rel=\"self\" href=\"http://roar.apotomo.de\" media="web"/>}, @link.to_xml
    end
  end
end
