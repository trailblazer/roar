require 'test_helper'
require 'roar/representer/json/hal'

class HalJsonTest < MiniTest::Spec
  let(:rpr) do
    Module.new do
      include Roar::Representer::JSON
      include Roar::Representer::JSON::HAL

      links :self do
        [{:lang => "en", :href => "http://en.hit"}, 
         {:lang => "de", :href => "http://de.hit"}]
      end

      link :next do
        "http://next"
      end
    end
  end

  subject { Object.new.extend(rpr) }

  describe "#links" do
    it "parses link array" do # TODO: remove me.
      obj = subject.from_json("{\"_links\":{\"self\":[{\"lang\":\"en\",\"href\":\"http://en.hit\"},{\"lang\":\"de\",\"href\":\"http://de.hit\"}]}}")
      obj.links.must_equal "self" => [link(:rel => :self, :href => "http://en.hit", :lang => :en), link(:rel => :self, :href => "http://de.hit", :lang => :de)]
    end

    it "parses single links" do # TODO: remove me.
      obj = subject.from_json("{\"_links\":{\"next\":{\"href\":\"http://next\"}}}")
      obj.links.must_equal "next" => link(:rel => :next, :href => "http://next")
    end

    it "parses link and link array" do
      obj = subject.from_json("{\"_links\":{\"next\":{\"href\":\"http://next\"}, \"self\":[{\"lang\":\"en\",\"href\":\"http://en.hit\"},{\"lang\":\"de\",\"href\":\"http://de.hit\"}]}}")
      obj.links.must_equal "next" => link(:rel => :next, :href => "http://next"), "self" => [link(:rel => :self, :href => "http://en.hit", :lang => :en), link(:rel => :self, :href => "http://de.hit", :lang => :de)]
    end

    it "rejects single links declared as array when parsing" do
      assert_raises TypeError do
        subject.from_json("{\"_links\":{\"self\":{\"href\":\"http://next\"}}}")
      end      
    end

    it "renders link and link array" do
      subject.to_json.must_equal "{\"_links\":{\"self\":[{\"lang\":\"en\",\"href\":\"http://en.hit\"},{\"lang\":\"de\",\"href\":\"http://de.hit\"}],\"next\":{\"href\":\"http://next\"}}}"
    end
  end

  describe "#prepare_links!" do
    it "should map link arrays correctly" do
      subject.send :prepare_links!
      subject.links.must_equal "self" => [link(:rel => :self, :href => "http://en.hit", :lang => "en"),link(:rel => :self, :href => "http://de.hit", :lang => "de")], "next" => link(:href => "http://next")
    end
  end


  describe "HAL/JSON" do
    before do
      Bla = Module.new do
        include Roar::Representer::JSON::HAL
        property :value
        link :self do
          "http://items/#{value}"
        end
      end

      @order_rep = Module.new do
        include Roar::Representer::JSON::HAL
        property :id
        collection :items, :class => Item, :extend => Bla, :embedded => true
        link :self do
          "http://orders/#{id}"
        end
      end

      @order = Order.new(:items => [Item.new(:value => "Beer")], :id => 1).extend(@order_rep)
    end

    it "render links and embedded resources according to HAL" do
      assert_equal "{\"id\":1,\"_embedded\":{\"items\":[{\"value\":\"Beer\",\"_links\":{\"self\":{\"href\":\"http://items/Beer\"}}}]},\"_links\":{\"self\":{\"href\":\"http://orders/1\"}}}", @order.to_json
    end

    it "parses links and resources following the mighty HAL" do
      @order.from_json("{\"id\":2,\"_embedded\":{\"items\":[{\"value\":\"Coffee\",\"_links\":{\"self\":{\"href\":\"http://items/Coffee\"}}}]},\"_links\":{\"self\":{\"href\":\"http://orders/2\"}}}")
      assert_equal 2, @order.id
      assert_equal "Coffee", @order.items.first.value
      assert_equal "http://items/Coffee", @order.items.first.links[:self].href
      assert_equal "http://orders/2", @order.links[:self].href
    end

    it "doesn't require _links and _embedded to be present" do
      @order.from_json("{\"id\":2}")
      assert_equal 2, @order.id
      assert_equal [], @order.items
      @order.links.must_equal({})
    end
  end
end
