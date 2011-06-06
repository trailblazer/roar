require 'test_helper'
require 'roar/representer/feature/hypermedia'

class HypermediaTest
  describe "Hypermedia" do
    class Bookmarks
      include Roar::Representer::Feature::Hypermedia
    end
    
    before do
      Hyperlink = Roar::Representer::XML::Hyperlink # TODO: move to abstract module.
      @b = Bookmarks.new
      @b.links = [Hyperlink.from_attributes({"rel" => "self", "href" => "http://self"}), Hyperlink.from_attributes({"rel" => "next", "href" => "http://next"})]
    end
    
    describe "#links" do
      it "returns links" do
        assert_kind_of Roar::Representer::Feature::Hypermedia::LinkCollection, @b.links
        assert_equal 2, @b.links.size
      end
      
      it "works with empty links set" do
        assert_equal nil, Bookmarks.new.links # default empty array doesn't make sense.
      end
    end
    
    
    it "responds to links #[]" do
      assert_equal "http://self", @b.links["self"]
      assert_equal "http://self", @b.links[:self]
      assert_equal "http://next", @b.links[:next]
      assert_equal nil, @b.links[:prev]
    end
  end
end
