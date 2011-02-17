require 'test_helper'

class TestHelperTest < MiniTest::Spec
  describe "TestModel" do
    it "is comparable" do
      assert_equal      TestModel.new(:id => 1), TestModel.new(:id => 1)
      assert  TestModel.new(:id => 1) != TestModel.new(:id => 2)
    end
  end
end
