require 'test_helper'
require 'roar/representer/feature/http_verbs'

class HttpVerbsTest < MiniTest::Spec
  class BandRepresenter
    include Roar::Representer::XML
    self.representation_name = :band
    
    property :name
    property :label
    
    include Roar::Representer::Feature::HttpVerbs
  end
  
  describe "HttpVerbs" do
    before do
      @r = BandRepresenter.new
    end
    
    # TODO: assert that Restfulie#post receives the correct document.
    
    it "#post deserializes the incoming representation and returns it" do
      @r.name = "Strung Out"
      rep = @r.post("http://localhost:9999/band", "application/xml")
      assert_equal "Strung Out", rep.name
      assert_equal "n/a", rep.label
    end
    
    it "#post! deserializes the incoming representation and replaces attributes" do
      @r.name = "Strung Out"
      assert_equal nil, @r.label
      @r.post!("http://localhost:9999/band", "application/xml")
      assert_equal "Strung Out", @r.name
      assert_equal "n/a", @r.label
    end
    
    
    
    it "#put deserializes the incoming representation and returns it" do
      @r.name   = "Strung Out"
      @r.label  = "Fat Wreck"
      rep = @r.put("http://localhost:9999/band/strungout", "application/xml")
      assert_equal "Strung Out", rep.name
      assert_equal "Fat Wreck", rep.label
    end
  end
end
