require 'test_helper'

class ModelTest < MiniTest::Spec
  describe "HttpVerbs" do
    before do
      @klass = Class.new(TestModel) do
        include Roar::Model::HttpVerbs
        
        def self.resource_host
          "http://localhost:9999/test/"
        end
        
      end
      @o = @klass.new
    end
    
    it "#get returns deserialized object from " do
      assert_equal({"id" => "4711"},  @klass.get(4711).attributes)
    end
  end
  
  
  describe "The Model API" do
    before do
      @klass = class Dog
        include Roar::Model
      end
    end
    
    it "the constructor accepts attributes" do
      assert_equal({"id" => "4711"},  @klass.new({"id" => "4711"}).attributes)
    end
    
    it "responds to .model_name" do
      assert_equal "model_test/dog", @klass.model_name
    end
  end
end
