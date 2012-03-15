require 'roar/representer/json/hal'

class HalJsonTest < MiniTest::Spec
  module SongRepresenter
    include Roar::Representer::JSON
    include Roar::Representer::JSON::HAL::Links
    
    link :self do
      "http://self"
    end
    
    link :next do
      "http://hit"
    end
  end
  
  describe "JSON::HAL::Links" do
    before do
      @song = Object.new.extend(SongRepresenter)
    end
    
    it "render links" do
      assert_equal "{\"_links\":{\"self\":\"http://self\",\"next\":\"http://hit\"}}", @song.to_json
    end
    
    it "parses incoming JSON links correctly" do
      @song.from_json "{\"_links\":{\"self\":\"http://self\"}}"
      assert_equal "http://self", @song.links[:self]
      assert_equal nil, @song.links[:next]
    end
  end
  
  
  describe "HAL/JSON" do
    before do
      @song = Object.new.extend(SongRepresenter)
    end
    
    
  end
  
  
  
end
