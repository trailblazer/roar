require 'roar/representer/json/hal'

class HalJsonTest < MiniTest::Spec
  module SongRepresenter
    include Roar::Representer::JSON::HAL
    
    link :self do
      "http://self"
    end
  end
      
  describe "HAL/JSON" do
    before do
      @song = Object.new.extend(SongRepresenter)
    end
    
    it "what" do
      assert_equal "{\"_links\":{\"self\":\"http://self\"}}", @song.to_json
    end
    
    it "parses incoming JSON links correctly" do
      @song.from_json "{\"_links\":{\"self\":\"http://self\"}}"
      assert_equal "http://self", @song.links[:self]
    end
  end
end
