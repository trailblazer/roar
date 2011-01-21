require 'test_helper'
require "active_support/core_ext/class/attribute"
require "hooks/inheritable_attribute"

class RepresenterTest < MiniTest::Spec
  Collection = Roar::Representation::UnwrappedCollection
  
  class TestModel
    include Roar::Representer::Xml
    
    extend Hooks::InheritableAttribute
    # TODO: Move to Representer::Xml
    inheritable_attr :xml_collections
    self.xml_collections = {}
    
    
    attr_accessor :attributes
    
    def self.model_name
      "test"
    end
    
    def initialize(attributes={})
      @attributes = attributes
    end
  end
  
  describe ".collection within .xml" do
    before do
      @c = Class.new(TestModel)
    end
    
    it "sets the class attribute" do
      assert_equal({}, @c.xml_collections)
      @c.xml do
        collection :items
      end
      
      assert_equal({:items => {}}, @c.xml_collections)
    end
    
  end
  
  describe "A Model with mixed-in Roar::Representer::Xml" do
    before do
      @c = Class.new(TestModel)
      @l = @c.new "name" => "tucker", "items" => [{}, {}]
      
      @c.collection :items
    end
    
    describe "attributes defined as collection" do
      it "#to_xml doesn't wrap collection attributes" do
        assert_equal "<test>
  <name>tucker</name>
  <item>\n  </item>
  <item>\n  </item>
</test>\n", @l.to_xml(:skip_instruct=>true)  # FIXME: make standard/#as_xml
      end
    
      it ".from_xml pushes deserialized items to the pluralized attribute" do
        assert_equal @c.new("name" => "tucker", "items" => ["Beer", "Peanut Butter"]).attributes, @c.from_xml("<test>
  <name>tucker</name>
  <item>Beer</item>
  <item>Peanut Butter</item>
  </test>").attributes
      end
      
      it ".from_xml pushes one single deserialized item to the pluralized attribute" do
        assert_equal @c.new("name" => "tucker", "items" => ["Beer"]).attributes, @c.from_xml("<test>
    <name>tucker</name>
    <item>Beer</item>
  </test>").attributes
      end
    end
          
      it ".collection respects :class in .from_xml" do 
        @c.xml do
          collection :item, :class => Item  # in: calls Item.from_hash(<item>...</item>), +above. out: item.to_xml
        end
        
        @l = @c.from_xml("<local>
  <name>tucker</name>
  <item>beer</item>
  <item>chips</item>
</local>")

        assert_equal [Item.new(:beer), Item.new(:chips)], @l.items
      end
      
  end
  
  
  describe "UnwrappedCollection" do
    before do
      @l = Collection.new([{:number => 1}, {:number => 2}])
      @xml = Builder::XmlMarkup.new
    end
    
    it "#to_xml returns contained items without a wrapping tag" do
      @l.to_xml(:builder => @xml)
      assert_equal "<?xml version=\"1.0\" encoding=\"UTF-8\"?><hash><number type=\"integer\">1</number></hash><?xml version=\"1.0\" encoding=\"UTF-8\"?><hash><number type=\"integer\">2</number></hash>", @xml.target!
    end
    
    it "#to_xml works with one single item" do
      Collection.new([{:number => 1}]).to_xml(:builder => @xml, :skip_instruct => true)
      assert_equal "<hash><number type=\"integer\">1</number></hash>", @xml.target!
    end
    
    it "#to_xml accepts options" do
      @l.to_xml(:builder => @xml, :skip_instruct => true, :skip_types => true)
      assert_equal "<hash><number>1</number></hash><hash><number>2</number></hash>", @xml.target!
    end
    
    it "#to_xml works in a nested hash" do
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
    
    it "#to_xml works with contained objects that respond to #to_xml themselves" do
      class Method
        def initialize(verb) @verb = verb end
        def to_xml(o) o[:builder].tag!(:method, :type => @verb) end
      end
      
      @l = Collection.new([Method.new(:PUT), Method.new(:GET)])
      @l.to_xml(:builder => @xml)
      assert_equal "<method type=\"PUT\"/><method type=\"GET\"/>", @xml.target!
    end 
  end
end
