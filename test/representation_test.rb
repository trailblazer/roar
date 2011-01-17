require 'test_helper'

require 'active_model'
require 'roar/representation'

class TestModel
  include Roar::Representation

    extend ActiveModel::Naming  # gives us Class.model_name  
  
  
  #include ActiveModel::AttributeMethods
  #    define_attribute_methods ['name']
      
  
  attr_accessor :attributes
  def initialize(attributes)
    @attributes = attributes
  end
  
  def name  # FIXME: how can AM do that for me?
    attributes["name"]
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
    end
  
  end
end
