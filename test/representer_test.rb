require 'test_helper'

class RepresenterTest < MiniTest::Spec
  #it "requires the mime-type it represents in the constructor" do
  #  @r = Roar::Representer::Base.new("ruby/serialized")
  #  assert_equal "ruby/serialized", @r.mime_type
  #end
  describe "Representer" do
    before do
      @c = Class.new(Roar::Representer::Base)
    end
    
    it "requires the represented instance in the constructor" do
      @r = Roar::Representer::Base.new("beer")
      assert_equal "beer", @r.represented
    end
    
    it "provides represented_class class accessor" do
      @c.represented_class = String
      assert_equal String, @c.represented_class
    end
    
    describe "represented_class" do
      before do
        @c.represented_class = String
        @subklass = Class.new(@c)
      end
      
      it "inherits" do
        assert_equal String, @c.represented_class
        assert_equal String, @subklass.represented_class
      end
      
      it "doesn't override superclasses settings" do
        @subklass.represented_class = Symbol
        
        assert_equal String, @c.represented_class
        assert_equal Symbol, @subklass.represented_class
      end
    end
    
    describe "represents" do
      it "requires represented_class and mime-type" do
        @c.represents String, :as => "application/xml"
        
        assert_equal String,            @c.represented_class
        assert_equal "application/xml", @c.mime_type  
      end
      
    end
    
  end
end
