require 'test_helper'

class RepresenterTest < MiniTest::Spec
  #it "requires the mime-type it represents in the constructor" do
  #  @r = Roar::Representer::Base.new("ruby/serialized")
  #  assert_equal "ruby/serialized", @r.mime_type
  #end
  
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
  
end
