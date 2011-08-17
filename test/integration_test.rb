require File.expand_path(File.dirname(__FILE__) + '/test_helper')

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
  
  
  require File.expand_path(File.dirname(__FILE__) + '/order_representers')
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
      
      # TODO: implement me.
      it "allows an ordering workflow" do
        # create representation with initial values:
        @o = ::JSON::Order.new(:client_id => 1)
        assert_equal 1, @o.client_id
        
        @o.post!("http://localhost:9999/orders", "application/order+json")
        # check HATEOAS:
        #@r.extend Roar::Representer::Feature::Hypermedia
        
        assert_equal "http://localhost:9999/orders/1/items",     @o.links[:items]
        assert_equal "http://localhost:9999/orders/1",           @o.links[:self]
        
        
        # manually POST item:
        @i = ::JSON::Item.new(:article_id => "666-S", :amount => 1)
        @i.post!(@o.links[:items], "application/item+json")
        @o.get!(@o.links[:self], "application/order+json")
        
        # check if item is included in order:
        assert_equal 1, @o.items.size
        assert_equal @i.to_attributes, @o.items.first.to_attributes
        
        
        ###@@o.delete!(@o.links[:self])
        
        # use the DSL to add items:
        #@o.links[:items].post(:article_id => "666-S", :amount => 1)
        
        #@o.items.post(:article_id => "666-S", :amount => 1)
        
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
