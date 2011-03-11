require 'test_helper'

class Article
  include Roar::Model
  include Roar::Representer::Xml
end


class Position
  include Roar::Model
  include Roar::Representer::Xml
  
  xml do
    has_proxied :article, :class => Article
  end
  
  def number
    attributes["number"]
  end
  
  def article
    attributes["article"]
  end
end

class Order
  include Roar::Model
  include Roar::Model::HttpVerbs
  
  # FIXME: how to know xml?
include Roar::Representer::Xml
  def self.represents(*)
    puts "IMPLEMENT ME!"
  end
  
  # accepts "application/xml", :with => Roar::Representer::Xml  # alias to accepts_xml.
  #represents "application/xml", :with => Roar::Representer::Xml do has_many ... end
  represents "application/xml", :with => Roar::Representer::Xml do
    has_many :items, :class => Position
  end
  # provides
  
  
  self.resource_base= "http://localhost:9999/orders/"
  
  # FIXME: shortcut for see above.
  xml do
    has_many :items, :class => Position
    # attribute / annotated
  end
  
  def items
    attributes["items"]
  end
end



class OrderClientIntegrationTest < MiniTest::Spec
  describe "A classic shopping cart scenario" do
    describe "getting an empty order" do
      it "retrieves the representation" do
        @order = Order.get("1")
        assert_kind_of Order, @order
        assert_equal [], @order.items
      end
      
    end
    
    describe "order with items" do
      it "retrieves the representation" do
        @order = Order.get("2")
        assert_kind_of Order, @order
        
        @items = @order.items
        assert_equal "1", @items[0].number
        assert_equal "2", @items[1].number
        
        # a grouping describe "proxy" would be cool here.
        @article = @items[0].article
        @article.finalize!
        assert_equal({"id" => "666"}, @article.attributes)
        
      end
      
    end
    
  end
end
