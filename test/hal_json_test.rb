require 'test_helper'
require 'roar/representer/json/hal'

class HalJsonTest < MiniTest::Spec
  describe "HAL/JSON" do
    before do
      ProductRepresenter = Module.new do
        include Roar::Representer::JSON::HAL
        property :id, :from => :href, :as => "/products/?"
        property :name
        property :title
      end

      OrderRepresenter = Module.new do
        include Roar::Representer::JSON::HAL
        link :self do
          "/orders/#{id}"
        end
        link :upsell do
          upsells
        end
        property :total
        property :currency
        property :status
      end

      FactoryRepresenter = Module.new do
        include Roar::Representer::JSON::HAL
        link :self do
          "/orders"
        end
        link :rel => :next do
          "/orders?page=2"
        end
        link :rel => :find, :templated => true do
          "/orders{?id}"
        end
        collection :orders, :class => Order, :extend => OrderRepresenter, :embedded => true
        property :currentlyProcessing
        property :shippedToday
      end

      order1 = Order.new(:id => 1, :total => 30.0, :currency => 'USD', :status => 'shipped', :upsells => []).extend(OrderRepresenter)
      order1.upsells << Product.new(:id => 452, :name => "FP01", :title => "Flower Pot").extend(ProductRepresenter)
      order1.upsells << Product.new(:id => 832, :name => "HD77", :title => "Hover Donkey").extend(ProductRepresenter)
      order2 = Order.new(:id => 2, :total => 20.0, :currency => 'USD', :status => 'processing', :upsells => []).extend(OrderRepresenter)
      @factory = Factory.new(:orders => [], :currentlyProcessing => 14, :shippedToday => 20).extend(FactoryRepresenter)
      @factory.orders << order1
      @factory.orders << order2
    end

    it "render links and embedded resources according to HAL" do
      assert_equal "{\"_links\":{\"self\":{\"href\":\"/orders\"},\"next\":{\"href\":\"/orders?page=2\"},\"find\":{\"templated\":true,\"href\":\"/orders{?id}\"}},\"_embedded\":{\"orders\":[{\"_links\":{\"self\":{\"href\":\"/orders/1\"},\"upsell\":[{\"href\":\"/products/452\",\"name\":\"FP01\",\"title\":\"Flower Pot\"},{\"href\":\"/products/832\",\"name\":\"HD77\",\"title\":\"Hover Donkey\"}]},\"total\":30.0,\"currency\":\"USD\",\"status\":\"shipped\"},{\"_links\":{\"self\":{\"href\":\"/orders/2\"},\"upsell\":[]},\"total\":20.0,\"currency\":\"USD\",\"status\":\"processing\"}]},\"currentlyProcessing\":14,\"shippedToday\":20}", @factory.to_json
    end

    it "parses links and resources following the mighty HAL" do
      @factory.from_json("{\"_links\":{\"self\":{\"href\":\"/orders\"},\"next\":{\"href\":\"/orders?page=2\"},\"find\":{\"templated\":true,\"href\":\"/orders{?id}\"}},\"_embedded\":{\"orders\":[{\"_links\":{\"self\":{\"href\":\"/orders/1\"}},\"total\":30.0,\"currency\":\"USD\",\"status\":\"shipped\"},{\"_links\":{\"self\":{\"href\":\"/orders/2\"}},\"total\":20.0,\"currency\":\"USD\",\"status\":\"processing\"}]},\"currentlyProcessing\":14,\"shippedToday\":20}")
      assert_equal 2, @factory.orders.length
      assert_equal "USD", @factory.orders.first.currency
      assert_equal "/orders/1", @factory.orders.first.links[:self].href
      assert_equal "/orders", @factory.links[:self].href
    end

    it "doesn't require _links and _embedded to be present" do
      @factory.from_json("{\"shippedToday\":2}")
      assert_equal 2, @factory.shippedToday
      assert_equal [], @factory.orders
      assert_equal [], @factory.links
    end
  end
end
