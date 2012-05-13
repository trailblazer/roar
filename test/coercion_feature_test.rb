require 'test_helper'
require 'roar/representer/feature/coercion'

class CoercionFeatureTest < MiniTest::Spec
  describe "Coercion" do
    class ImmigrantSong
      include Roar::Representer::JSON
      include Roar::Representer::Feature::Coercion
      
      property :composed_at, :type => DateTime, :default => "May 12th, 2012"
    end
    
    it "coerces into the provided type" do
      song = ImmigrantSong.new.from_json("{\"composed_at\":\"November 18th, 1983\"}")
      assert_equal DateTime.parse("Fri, 18 Nov 1983 00:00:00 +0000"), song.composed_at
    end
  end
end
