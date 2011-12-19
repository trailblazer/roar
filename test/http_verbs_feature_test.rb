require 'test_helper'
require 'roar/representer/feature/http_verbs'
require 'roar/representer/json'

class HttpVerbsTest < MiniTest::Spec
  module BandRepresenter
    include Roar::Representer::JSON
    
    property :name
    property :label
  end
  
  describe "HttpVerbs" do
    before do
      @band = Object.new
      @band.extend(BandRepresenter)
      @band.extend(Roar::Representer::Feature::HttpVerbs)
    end
    
    describe "HttpVerbs.get" do
      it "returns instance from incoming representation" do
        @Band = Class.new do
          include Roar::Representer::JSON
          include BandRepresenter
          include Roar::Representer::Feature::HttpVerbs
        end
        @band = @Band.get("http://localhost:9999/bands/slayer", "application/json")
        assert_equal "Slayer", @band.name
        assert_equal "Canadian Maple", @band.label
      end
    end
    
    describe "#get" do
      it "updates instance with incoming representation" do
        @band.get("http://localhost:9999/bands/slayer", "application/json")
        assert_equal "Slayer", @band.name
        assert_equal "Canadian Maple", @band.label
      end
    end
    
    describe "#post" do
      it "updates instance with incoming representation" do
        @band.name = "Strung Out"
        assert_equal nil, @band.label
        
        @band.post("http://localhost:9999/bands", "application/xml")
        assert_equal "Strung Out", @band.name
        assert_equal "n/a", @band.label
      end
    end
    
    describe "#put" do
      it "updates instance with incoming representation" do
        @band.name   = "Strung Out"
        @band.label  = "Fat Wreck"
        @band.put("http://localhost:9999/bands/strungout", "application/xml")
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
