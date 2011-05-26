require 'test_helper'
require 'roar/representer/feature/http_verbs'
require 'roar/representer/feature/hypermedia'

class RepresenterIntegrationTest < MiniTest::Spec
  class BandRepresenter < Roar::Representer::XML
    self.representation_name = :band
    
    property :name
    property :label
    
    include Roar::Representer::Feature::HttpVerbs
    
    
    link :search do
      search_url
    end
    
    link :self do
      order_url(represented)
    end
  end
  
  describe "Representer as client" do
    it "can be created with #new" do
      # create representation with initial values:
      @r = BandRepresenter.new(:name => "Bigwig")
      assert_equal "Bigwig", @r.name
      
      @r = @r.post("http://localhost:9999/band", "application/band+xml")
      assert_equal "n/a", @r.label
      
      # check HATEOAS:
      @r.extend Roar::Representer::Feature::Hypermedia
      assert_equal "http://search",       @r.links[:search]
      assert_equal "http://band/strungout",  @r.links[:self]
    end
    
  end
end
