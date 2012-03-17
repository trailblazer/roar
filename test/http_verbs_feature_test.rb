require 'test_helper'
require 'roar/representer/feature/http_verbs'
require 'roar/representer/json'

class HttpVerbsTest < MiniTest::Spec
  module BandRepresenter
    include Roar::Representer::JSON
    
    property :name
    property :label
  end
  
  # keep this class clear of Roar modules.
  class Band
    attr_accessor :name, :label
  end
  
  
  describe "HttpVerbs" do
    before do
      @band = Band.new
      @band.extend(BandRepresenter)
      @band.extend(Roar::Representer::Feature::HttpVerbs)
    end
    
    describe "HttpVerbs.get" do
      it "returns instance from incoming representation" do
        # let's pretend the user wants Roar class methods.
        @Band = Class.new do
          include Roar::Representer::JSON
          include BandRepresenter
          include Roar::Representer::Feature::HttpVerbs
          attr_accessor :name, :label
        end
        @band = @Band.get("http://roar.example.com/bands/slayer", "application/json")
        assert_equal "Slayer", @band.name
        assert_equal "Canadian Maple", @band.label
      end
    end
    
    describe "#get" do
      it "updates instance with incoming representation" do
        @band.get("http://roar.example.com/bands/slayer", "application/json")
        assert_equal "Slayer", @band.name
        assert_equal "Canadian Maple", @band.label
      end
    end
    
    describe "#post" do
      it "updates instance with incoming representation" do
        @band.name = "Strung Out"
        assert_equal nil, @band.label
        
        @band.post("http://roar.example.com/bands", "application/xml")
        assert_equal "Strung Out", @band.name
        assert_equal "n/a", @band.label
      end
    end
    
    describe "#put" do
      it "updates instance with incoming representation" do
        @band.name   = "Strung Out"
        @band.label  = "Fat Wreck"
        @band.put("http://roar.example.com/bands/strungout", "application/xml")
        assert_equal "Strung Out", @band.name
        assert_equal "Fat Wreck", @band.label
      end
    end
    
    describe "#delete" do
      
    end
    
    describe "#patch" do
      
    end
  end
end
