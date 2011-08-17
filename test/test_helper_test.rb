require File.expand_path(File.dirname(__FILE__) + '/test_helper')
require 'roar/model'

class AssertModelTest < MiniTest::Spec
  class Song
    include Roar::Model
    accessors :title
  end

  class Album
    include Roar::Model
    accessors :songs
  end
  
  class Play
    include Roar::Model
    accessors :song
  end
  

  describe "#assert_model" do
    before do
      @jerk     = Song.new(:title => "Jerk")
      @sellout  = Song.new(:title => "Sellout")
      @saleout  = Song.new(:title => "Sellout")
    end
    
    it "compares to plain models" do
      assert_model @jerk,     @jerk
      assert_model @sellout,  @saleout
      
      assert_raises MiniTest::Assertion do
        assert_model @jerk, @sellout
      end
    end
    
    it "compares nested models" do
      @play    = Play.new(:song => @sellout)
      @play_2  = Play.new(:song => @saleout)
      assert_model @play, @play_2
      
      assert_raises MiniTest::Assertion do
        assert_model @play, Play.new(:song => @jerk)
      end
    end
    
    it "compares nested models in collections" do
      @stay_asleep = Album.new(:songs => [@jerk, @sellout])
      @stay_asleep_ripped = Album.new(:songs => [@jerk, @saleout])
      assert_model @stay_asleep, @stay_asleep_ripped
      
      assert_raises MiniTest::Assertion do
        assert_model assert_model @stay_asleep, Album.new(:songs => [@jerk])
      end
    end
    
    
  end
end
