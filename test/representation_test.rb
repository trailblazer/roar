require 'test_helper'



# Auftrag.from_xml
#   @name =
#   @items = [Angebot.from_xml, Angebot.from_xml]
#
# serializable_hash -> serializable_xml_node_configuration -> xml

#
# auftrag.serializable_hash (nur noch rudimentäre datenstrukturen)
# auftrag.to_hash
#   
class TestModel
  include Roar::Representation

  extend ActiveModel::Naming  # gives us Class.model_name
  
  attr_accessor :attributes
  def initialize(attributes={})
    @attributes = attributes
  end
  
  def name  # FIXME: how can AM do that for me?
    attributes["name"]
  end
end

class SimpleModel
  extend ActiveModel::Naming  # gives us Class.model_name
  
  attr_accessor :attributes
  def initialize(attributes={})
    @attributes = attributes
  end
end

class List < TestModel
  def item
    attributes["item"]
  end
  
  
  def to_xml(*)   
    attributes["item"] = Roar::Representation::UnwrappedCollection.new(item) # FIXME: don't override a local attribute, do that in #serializable_hash!
    super 
    # xml currently uses attributes, which must be serializable_hash
  end
  
end

class Item < SimpleModel
  include Roar::Representer::Xml
  
  def to_xml(options); options[:builder].tag! :item, attributes; end
  def self.from_xml(xml); self.new Hash.from_xml(xml)["item"]; end
end
class ItemTest < MiniTest::Spec
  before do
    @i = Item.new("Beer") 
  end
  
  it "responds to #to_xml" do
    assert_equal "<item>Beer</item>", @i.to_xml
  end
  
  it "responds to #from_xml" do
    assert_equal @i.attributes, Item.from_xml("<item>Beer</item>").attributes
  end
end


class RepresenterTest < MiniTest::Spec
  describe "An ordinary Representer" do
    before do
      @o = TestModel.new :name => "Joe"
      @o.instance_eval do
        extend Roar::Representer::Xml
      end
    end
    
    it "#to_xml renders a generic representation" do
      assert_equal "<TestModel>\n  <name>Joe</name>\n</TestModel>\n", @o.to_xml
    end
    
    it "#to_xml respects #attributes_for_xml" do
      @o.instance_eval do
        def attributes_for_xml(*) # user overrides it in the "representing" class.
          super.merge!({"kind" => "nice"})
        end
      end
      assert_equal "<TestModel>\n  <name>Joe</name>\n  <kind>nice</kind>\n</TestModel>\n", @o.to_xml
    end
    
    
    describe "additional import/export" do
      before do
        class Local < TestModel
          include Roar::Representer::Xml
          def self.xml(*)#
          end
          
          def items
            attributes["items"]
          end
          
        end
        
        
        
        @l= Local.new "name" => "tucker", "orders" => [Item.new("beer"), Item.new("chips")]
      end
      
      it "collections are not wrapped implicitely" do
        Local.xml do
          collection :items  # in: pushes <item> into items attribute. out: packs items into UnwrappedCollection.
        end
        
        assert_equal "<RepresenterTest::Local>\n  <name>tucker</name>\n  <orders>\n    <item>beer</item>\n    <item>chips</item>\n  </orders>\n</RepresenterTest::Local>\n", @l.to_xml(:skip_instruct=>true)  # FIXME: make standard/#as_xml
      end
      
      it ".collection items are pushed into the pluralized attribute in .from_xml" do
        Local.xml do
          collection :items  # in: pushes <item> into items attribute.
        end
        
        assert_equal @l, Local.from_xml("<local>
  <name>tucker</name>
  <item>beer</item>
  <item>chips</item>
</local>")
      end
          
      it ".collection respects :class in .from_xml" do 
        Local.xml do
          selfcontained :item, :class => Item  # in: calls Item.from_hash(<item>...</item>), +above. out: item.to_xml
        end
        
        @l = Local.from_xml("<local>
  <name>tucker</name>
  <item>beer</item>
  <item>chips</item>
</local>")

        assert_equal [Item.new(:beer), Item.new(:chips)], @l.items
      end
      
      
      it "bla" do
        assert_equal "expected", {:id => 9, :position => [{:b => "Hi"},{:b => "Hi"}]}.to_xml(:skip_types => true)
        assert_equal "expected", {:id => 9, :position => Roar::Representation::UnwrappedCollection.new([{:b => "Hi"},{:b => "Hi"}])}.to_xml(:skip_types => true)
      end
      
      
      
    end
    
  end
end

class RepresentationTest < MiniTest::Spec
  Collection = Roar::Representation::UnwrappedCollection
  
  describe "Representation" do
    before do
      @t = TestModel.new "name" => "tucker"
    end
    
    describe "ActiveModel dependency" do
      it "requires .model_name" do
        assert_equal "TestModel", @t.class.model_name.to_s
      end
      
      it "#serializable_hash requires #attributes" do
        assert_equal({"name" => "tucker"}, @t.serializable_hash)
      end
      
      it "#to_hash is aliased to #serializable_hash" do
        assert_equal(@t.serializable_hash, @t.to_hash)
      end
    end
    
    describe "Serialization" do
      it "#as_xml returns xml without instruct tag" do
        assert_equal("<test-model>\n  <name>tucker</name>\n</test-model>\n", @t.as_xml)
      end
      
      it "#to_xml returns #as_xml with instruct tag" do
        assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<test-model>\n  <name>tucker</name>\n</test-model>\n", @t.to_xml)
      end
      
      it "#from_xml reassigns attributes" do
        @t = TestModel.new({}).from_xml "<test-model>\n  <name>tucker</name>\n</test-model>\n"
        assert_equal({"name" => "tucker"}, @t.serializable_hash)
      end
    end
    
    
    describe "UnwrappedCollection" do
      before do
        @l = Collection.new([{:number => 1}, {:number => 2}])
        @xml = Builder::XmlMarkup.new
      end
      
      it "#to_xml returns contained items without a wrapping tag" do
        @l.to_xml(:builder => @xml) # TODO: replace with a simpler system.
        assert_equal "<?xml version=\"1.0\" encoding=\"UTF-8\"?><hash><number type=\"integer\">1</number></hash><?xml version=\"1.0\" encoding=\"UTF-8\"?><hash><number type=\"integer\">2</number></hash>", @xml.target!
      end
      
      it "#to_xml accepts options" do
        @l.to_xml(:builder => @xml, :skip_instruct => true, :skip_types => true)
        assert_equal "<hash><number>1</number></hash><hash><number>2</number></hash>", @xml.target!
      end
      
      it "works in a nested hash" do
        assert_equal "<hash>
  <order>
    <position>
      <article>Peanut Butter</article>
      <amount>1</amount>
    </position>
    <position>
      <article>Hoepfner Pils</article>
      <amount>2</amount>
    </position>
  </order>\n</hash>\n", {:order => {:position => Collection.new([
  {:article => "Peanut Butter", :amount => 1}, 
  {:article => "Hoepfner Pils", :amount => 2}])}}.to_xml(:skip_instruct => true, :skip_types => true)
      end
      
      it "works with contained objects that respond to #to_xml themselves" do
        class Method
          def initialize(verb) @verb = verb end
          def to_xml(o) o[:builder].tag!(:method, :type => @verb) end
        end
        
        @l = Collection.new([Method.new(:PUT), Method.new(:GET)])
        @l.to_xml(:builder => @xml)
        assert_equal "<method type=\"PUT\"/><method type=\"GET\"/>", @xml.target!
      end 
    end
    
    describe "EXAMPLE: An order with nested items and collections" do
      it "items is UnwrappedCollection " do
        @l= List.new "name" => "tucker", "item" => [{:name => "beer"}, {:name => "chips"}]
        
        # to_hash:
        assert_equal({"item"=>[{:name => "beer"}, {:name => "chips"}], "name"=>"tucker"}, @l.to_hash) # still original types.
        
        
        assert_equal "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<list>\n  <name>tucker</name>\n  <item>\n    <name>beer</name>\n  </item>\n  <item>\n    <name>chips</name>\n  </item>\n</list>\n", @l.to_xml
      end
      
      it ".from_xml delegates to #from_xml" do
        @l = List.from_xml "<list>\n  <name>tucker</name>\n</list>\n"
        assert_equal({"name"=>"tucker"}, @l.to_hash)
      end
      
      it ".from_xml respects UnwrappedCollection" do
        @l = List.from_xml "<list>\n  <name>tucker</name> <item>Beer</item><item>Chips</item></list>\n"
        assert_equal({"item"=>["Beer", "Chips"], "name"=>"tucker"}, @l.to_hash)
      end
      
      it ".from_xml respects UnwrappedCollection" do
        @l = List.from_xml "<list>\n  <name>tucker</name> <item>Beer</item><item>Chips</item></list>\n"
        assert_equal({"item"=>["Beer", "Chips"], "name"=>"tucker"}, @l.to_hash)
      end
    end
    
  end
end
