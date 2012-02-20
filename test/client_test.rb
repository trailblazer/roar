require 'test_helper'
require 'roar/representer/feature/client'

class ClientTest < MiniTest::Spec
  describe "Client" do
    before do
      @representer = Module.new do
        include Roar::Representer
        property :name
        property :band
      end
      
      @song = Object.new.extend(@representer)
    end
    
    it "should add accessors" do
      @song.extend Roar::Representer::Feature::Client
      @song.name = "Social Suicide"
      @song.band = "Bad Religion"
      assert_equal "Social Suicide", @song.name
      assert_equal "Bad Religion", @song.band
    end
  end
end
