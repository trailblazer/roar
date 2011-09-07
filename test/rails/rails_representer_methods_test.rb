require 'test_helper'
require "dummy/config/environment"
require 'roar/rails'

module Representer
  module JPG
    class Song; end
    class Album < Roar::Representer::XML; end
  end
end



class RailsRepresenterMethodsTest < MiniTest::Spec
  describe "Rails::RepresenterMethods" do
    before do
      @c = Representer::JPG::Album  # TODO: mix Rails into Base, not XML only.
    end
    
    it "provides conventions for #collection" do
      @c.collection :songs
      
      @d = @c.representable_attrs.first
      assert_equal Representer::JPG::Song, @d.sought_type
      assert @d.array?
    end
    
    it "provides conventions for #representation_name" do
      assert_equal "album", @c.representation_name
    end
  end
end
