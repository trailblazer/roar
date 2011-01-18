require 'test_helper'

require 'active_model'
require 'roar/representation'

class TestModel
  include Roar::Representation

  extend ActiveModel::Naming  # gives us Class.model_name
  
  attr_reader :attributes
  def initialize(attrs)
    #@attributes = attributes
    # FIXME: 
    @attributes = {}
    self.attributes=attrs
  end
  
  def attributes=(attrs)
    attrs.each do |k,v|
      if respond_to?(k+"=")
        send(k+"=", v)
      else
        @attributes[k] = v
      end
    end
  end
  
  def name  # FIXME: how can AM do that for me?
    attributes["name"]
  end
end

class List < TestModel
  def item
    attributes["item"]
  end
  
  def item=(items)
    puts "#item aufgerufen"
    attributes["item"] = UnwrappedCollection.new(items)
    puts attributes["item"].class.inspect
  end
  
end

  

class RepresentationTest < MiniTest::Spec
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
        require 'stringio'  # FIXME.
        @t = TestModel.new({}).from_xml "<test-model>\n  <name>tucker</name>\n</test-model>\n"
        assert_equal({"name" => "tucker"}, @t.serializable_hash)
      end
    end
    
    describe "UnwrappedCollection" do
      before do
        @c = Roar::Representation::UnwrappedCollection.new([{:b => "Hi"}, {:p => "Hey"}])
      end
      
      it "#to_xml returns contained items without a wrapping tag" do
        assert_equal "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  <b>Hi</b>\n</hash>\n\n<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<hash>\n  <p>Hey</p>\n</hash>\n", @c.to_xml
      end
      
      it "#to_xml accepts options" do
        assert_equal "<hash>\n  <b>Hi</b>\n</hash>\n\n<hash>\n  <p>Hey</p>\n</hash>\n", @c.to_xml(:skip_instruct => true)
      end
      
    end
    
    describe "EXAMPLE: An order with nested items and collections" do
      it "items is UnwrappedCollection " do
        puts "yo"
        @l= List.new "name" => "tucker", "item" => [{:name => "beer"}, {:name => "chips"}]
        
        assert_equal({"item"=>[{:name => "beer"}, {:name => "chips"}], "name"=>"tucker"}, @l.to_hash)
        assert_kind_of Roar::Representation::UnwrappedCollection, @l.attributes["item"]
        assert_equal "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<list>\n  <name>tucker</name>\n  <item>\n    <name>beer</name>\n  </item>\n  <item>\n    <name>chips</name>\n  </item>\n</list>\n", @l.to_xml
      end
      
      it ".from_xml delegates to #from_xml" do
        require 'stringio'  # FIXME.
        @l = List.from_xml "<list>\n  <name>tucker</name>\n</list>\n"
        assert_equal({"name"=>"tucker"}, @l.to_hash)
      end
      
      it ".from_xml respects UnwrappedCollection" do
        require 'stringio'  # FIXME.
        @l = List.from_xml "<list>\n  <name>tucker</name> <item>Beer</item><item>Chips</item></list>\n"
        assert_equal({"item"=>["Beer", "Chips"], "name"=>"tucker"}, @l.to_hash)
      end
    end
    
  end
end
