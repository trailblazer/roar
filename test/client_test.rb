require 'test_helper'

class ClientModelMethodsTest < MiniTest::Spec
  class TestModel
    include Roar::Client::ModelMethods
  end
  
  describe "The Client::ModelMethods API" do
    before do
      @klass = TestModel
    end
    
    it "the constructor accepts attributes" do
      assert_equal({"id" => "4711"},  @klass.new({"id" => "4711"}).attributes)
    end
    
    it "responds to .model_name" do
      assert_equal "ClientModelMethodsTest::TestModel", @klass.model_name
    end
  end
end
