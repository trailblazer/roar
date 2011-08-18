require File.expand_path(File.dirname(__FILE__) + '/test_helper')

class RepresenterTest < MiniTest::Spec
  describe "Representer" do
    before do
      @c = Class.new(Roar::Representer::Base)
    end
    
    it "aliases #representable_property to #property" do
      @c.property :title
      assert_equal "title", @c.representable_attrs.first.name
    end
    
    it "aliases #representable_collection to #collection" do
      @c.collection :songs
      assert_equal "songs", @c.representable_attrs.first.name
    end
    
    it "accepts property hash in #new" do
      @c.property :title
      assert_equal "Counting Down", @c.new(:title => "Counting Down").title
    end
    
  end
end
