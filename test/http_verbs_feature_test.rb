require 'test_helper'
require 'roar/representer/feature/http_verbs'

class HttpVerbsTest < MiniTest::Spec
  class Band
    include Roar::Representer::XML
    
    property :name
    property :label
    
    include Roar::Representer::Feature::HttpVerbs
  end
  
  describe "HttpVerbs" do
    before do
      @band = Band.new
    end
    
    describe "#get" do
      it "updates instance with incoming representation" do
        @band.name = "Strung Out"
        @band.get("http://localhost:9999/bands/slayer", "application/xml")
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
  end
end
