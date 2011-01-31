require 'test_helper'
require "active_support/core_ext/class/attribute"
require "hooks/inheritable_attribute"


# fixtures:  


class Item < TestModel
  def to_xml(options); options[:builder].tag! :item, attributes; end
  def self.from_xml(xml); self.new Hash.from_xml(xml)["item"]; end
  def ==(b)
    attributes == b.attributes
  end
end

class PublicXmlRepresenterAPITest < MiniTest::Spec
  describe "The public XML Representer API" do
    before do
      @c = Class.new(TestModel)
      @o = @c.new "name" => "Joe"
    end
    
    it "#attributes returns generic attributes hash" do
      assert_equal({"name" => "Joe"}, @o.attributes)
    end
    
    it "#attributes_for_xml returns attributes hash ready for xml rendering" do
      assert_equal({"name" => "Joe"}, @o.attributes_for_xml)
    end
    
    it "#to_xml renders XML as string" do
      assert_equal "<test>\n  <name>Joe</name>\n</test>\n", @o.to_xml
    end
    
    it ".from_xml creates model from xml" do
      assert_equal @o.attributes, @c.from_xml("<test>\n  <name>Joe</name>\n</test>\n").attributes
    end
    
    it ".from_attributes creates model from parsed XML attributes hash" do
      assert_equal @o.attributes, @c.from_xml_attributes("name" => "Joe").attributes
    end
    
    it ".from_attributes creates model from generic attributes hash" do
      assert_equal @o.attributes, @c.from_attributes("name" => "Joe").attributes
    end
    
    #it "#to_xml respects #attributes_for_xml" do
    #  @o.instance_eval do
    #    def attributes_for_xml(*) # user overrides it in the "representing" class.
    #      super.merge!({"kind" => "nice"})
    #    end
    #  end
    #  assert_equal "<TestModel>\n  <name>Joe</name>\n  <kind>nice</kind>\n</TestModel>\n", @o.to_xml
    #end
  end
end

class PrivateXmlRepresenterAPITest < MiniTest::Spec
  describe "The private XML Representer API" do
    before do
      @c = Class.new(TestModel)
      @o = @c.new "name" => "Joe", "drink" => "Beer"
    end
    
    it ".filter_attributes_for applies the passed block" do
      attributes = {"name" => "Joe", "drink" => "Beer"}
      @c.send :filter_attributes_for, attributes, {:drink => "Lager"} do |name, options|
        attributes.delete(name)      # modify the attributes.
        attributes[name.upcase] = options
      end
      assert_equal({"name" => "Joe", "DRINK" => "Lager"}, attributes)
    end
  end
end

class HasOneAndHasManyInRepresenterTest < MiniTest::Spec
  describe ".has_one within .xml" do
    before do
      @c = Class.new(TestModel)
      assert_equal({}, @c.xml_typed_entities)
    end
    
    it "sets the class attribute for deserialization" do
      @c.xml do
        has_one :item, :class => Item
      end
      
      assert_equal({:item => {:class => Item}}, @c.xml_typed_entities)
    end
    
    it "respects :class in .from_xml" do 
      @c.xml do
        has_one :item, :class => Item
      end
      
      @l = @c.from_xml("<test>
  <name>tucker</name>
  <item>beer</item>
</test>")

      assert_equal Item.new("beer"), @l.attributes["item"]
    end
  end
  
  describe ".has_proxied within .xml" do
    before do
      @c = Class.new(TestModel)
      assert_equal({}, @c.xml_typed_entities)
    end
    
    it "saves the wrapped configuration" do
      @c.xml do
        has_proxied :item, :class => TestModel
      end
      
      proxy_klass = @c.xml_typed_entities[:item][:class]
      assert_equal({:class => TestModel}, proxy_klass.options)
    end
    
    it "wraps the item in an EntityProxy in .from_xml" do 
      @c.xml do
        has_proxied :item, :class => TestModel
      end
      
      @l = @c.from_xml("<test>
  <item><uri>http://localhost:9999/test/1</uri></item>
</test>")
      
      @proxy = @l.attributes["item"]
      
      assert_kind_of EntityProxy, @proxy
      assert_equal "test", @proxy.class.model_name
      assert_equal({"uri" => "http://localhost:9999/test/1"}, @proxy.attributes)
      # we can now call #finalize!
    end
    
    it "returns the unfinalized xml in #to_xml" do 
      @c.xml do
        has_proxied :item, :class => TestModel
      end
      
      @l = @c.from_xml("<test>
  <item><uri>http://localhost:9999/test/1</uri></item>
</test>")

      assert_equal "<test>\n  <item>\n    <uri>http://localhost:9999/test/1</uri>\n  </item>\n</test>\n", @l.to_xml
    end
  end
  
  # UNIT
  describe ".has_many" do
    before do
      @c = Class.new(TestModel)
      assert_equal({}, @c.xml_collections)
    end
    
    it "saves the wrapped configuration" do
      @c.xml do
        has_many_proxied :items, :class => TestModel
      end
      
      proxy_klass = @c.xml_collections[:items][:class]
      assert_equal({:class => TestModel}, proxy_klass.options)
    end
  end
  
  # FUNCTIONAL
  describe ".has_many_proxied within .xml" do
    before do
      @c = Class.new(TestModel)
    end
    
    it "wraps the items in EntityProxys in .from_xml" do 
      @c.xml do
        has_many_proxied :items, :class => TestModel
      end
      
      @l = @c.from_xml("<test>
  <item><uri>http://localhost:9999/test/1</uri></item>
  <item><uri>http://localhost:9999/test/2</uri></item>
</test>")
      
      items = @l.attributes["items"]
      assert_equal 2, @l.attributes["items"].size
      
      items.each_with_index do |item, i|
        assert_kind_of EntityProxy, item, "#{item} not an EntityProxy"
        assert_equal "test", item.class.model_name
        assert_equal({"uri" => "http://localhost:9999/test/#{i+1}"}, item.attributes)
      end
    end
    
    it "returns the unfinalized xml in #to_xml" do 
      @c.xml do
        has_proxied :item, :class => TestModel
      end
      
      @l = @c.from_xml("<test>
  <item><uri>http://localhost:9999/test/1</uri></item>
</test>")

      assert_equal "<test>\n  <item>\n    <uri>http://localhost:9999/test/1</uri>\n  </item>\n</test>\n", @l.to_xml
    end
  end
  
  
  describe ".collection within .xml" do
    before do
      @c = Class.new(TestModel)
      assert_equal({}, @c.xml_collections)
    end
    
    it "sets the class attribute" do
      @c.xml do
        collection :items
      end
      
      assert_equal({:items => {}}, @c.xml_collections)
    end
    
    it "accepts options" do
      @c.xml do
        collection :items, :class => Item
      end
      
      assert_equal({:items => {:class => Item}}, @c.xml_collections)
    end
    
    it "is an alias to .has_many" do
      @c.xml do
        has_many :items
      end
      
      assert_equal({:items => {}}, @c.xml_collections)
    end
  end
  
  # DISCUSS: this is more like an integration test.
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
          collection :items, :class => Item  # in: calls Item.from_hash(<item>...</item>), +above. out: item.to_xml
        end
        
        @l = @c.from_xml("<test>
  <name>tucker</name>
  <item>beer</item>
  <item>chips</item>
</test>")

        assert_equal [Item.new("beer"), Item.new("chips")], @l.attributes["items"]
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
  
  class TestItemTest < MiniTest::Spec
    before do
      @i = Item.new("Beer") 
    end
    
    it "responds to #to_xml" do
      assert_equal "<item>Beer</item>", @i.to_xml(:builder => Builder::XmlMarkup.new)
    end
    
    it "responds to #from_xml" do
      assert_equal @i.attributes, Item.from_xml("<item>Beer</item>").attributes
    end
    
    it "responds to #==" do
      assert_equal Item.new("Beer"), @i
      assert Item.new("Auslese") != @i
    end
  end
end
