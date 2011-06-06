require 'test_helper'

require 'roar/representer/xml'
require 'roar/representer/json'

require 'roar/representer/feature/http_verbs'
require 'roar/representer/feature/hypermedia'

class RepresenterIntegrationTest < MiniTest::Spec
  module XML
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
  end
  
  # TODO: inherit properly.
  module JSON
    class BandRepresenter < Roar::Representer::JSON
      self.representation_name = :band
      
      property :name
      property :label
      
      include Roar::Representer::Feature::HttpVerbs
      include Roar::Representer::Feature::Hypermedia
      
      
      link :search do
        search_url
      end
      
      link :self do
        order_url(represented)
      end
    end
  end
  
  describe "Representer as client" do
    describe "JSON" do
      it "allows a POST workflow" do
        # create representation with initial values:
        @r = JSON::BandRepresenter.new(:name => "Bigwig")
        assert_equal "Bigwig", @r.name
        
        @r = @r.post("http://localhost:9999/band", "application/band+json")
        assert_equal "n/a", @r.label
        
        # check HATEOAS:
        #@r.extend Roar::Representer::Feature::Hypermedia
        assert_equal "http://search",         @r.links[:search]
        assert_equal "http://band/strungout", @r.links[:self]
      end
    end
    
    describe "XML" do
      it "allows a POST workflow" do
        # create representation with initial values:
        @r = XML::BandRepresenter.new(:name => "Bigwig")
        assert_equal "Bigwig", @r.name
        
        @r = @r.post("http://localhost:9999/band", "application/band+xml")
        assert_equal "n/a", @r.label
        
        # check HATEOAS:
        #@r.extend Roar::Representer::Feature::Hypermedia
        assert_equal "http://search",         @r.links[:search]
        assert_equal "http://band/strungout", @r.links[:self]
      end
    end
    
    
  end
end
