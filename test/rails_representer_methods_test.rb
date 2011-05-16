require 'test_helper'
require "dummy/config/environment"
require 'roar/rails'

module JPG
  class SongRepresenter; end
  class AlbumRepresenter < Roar::Representer::XML; end
end

class RailsRepresenterMethodsTest < MiniTest::Spec
  describe "Rails::RepresenterMethods" do
    before do
      @c = JPG::AlbumRepresenter  # TODO: mix Rails into Base, not XML only.
    end
    
    it "provides conventions for #collection" do
      @c.collection :songs
      
      @d = @c.representable_attrs.first
      assert_equal JPG::SongRepresenter, @d.sought_type
      assert @d.array?
    end
    
  end
  
end
