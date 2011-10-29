require 'test_helper'
require 'roar/representer/feature/hypermedia'

class HypermediaTest
  describe "Hypermedia Feature" do
    class Bookmarks
      include Roar::Representer::XML
      include Roar::Representer::Feature::Hypermedia
    end
    
    before do
      Hyperlink = Roar::Representer::XML::Hyperlink # TODO: move to abstract module.
      @b = Bookmarks.new
      @b.links = [Hyperlink.from_attributes({"rel" => "self", "href" => "http://self"}), Hyperlink.from_attributes({"rel" => "next", "href" => "http://next"})]
      
      @bookmarks = Class.new(Bookmarks) do
        self.representation_name = :bookmarks
      end
    end
    
    describe "#serialize" do
      it "sets up links before rendering" do
        @bookmarks.class_eval do
          link :self do "http://bookmarks" end
          link :all do "http://bookmarks/all" end
        end
        
        assert_xml_equal '<bookmarks>
                            <link rel="self" href="http://bookmarks"/>
                            <link rel="all" href="http://bookmarks/all"/>
                          </bookmarks>', @bookmarks.new.serialize
      end
      
      it "still works even if there are no links defined" do
        assert_xml_equal '<bookmarks/>', @bookmarks.new.serialize
      end
      
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
