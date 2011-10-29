require 'test_helper'
require 'roar/representer/feature/hypermedia'

class HypermediaTest
  describe "Hypermedia Feature" do
    class Bookmarks
      include Roar::Representer::XML
      include Roar::Representer::Feature::Hypermedia
    end
    
    before do
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
      before do
        @set  = Bookmarks.new
        hyper = Roar::Representer::XML::Hyperlink
        
        @set.links = [hyper.from_attributes({"rel" => "self", "href" => "http://self"}),
                      hyper.from_attributes({"rel" => "next", "href" => "http://next"})]
      end
      
      describe "#links=" do
        it "wraps links in a LinkCollection" do
          assert_kind_of Roar::Representer::Feature::Hypermedia::LinkCollection, @set.links
          assert_equal 2, @set.links.size
        end
      end
      
      describe "#link[]" do
        it "provides shorthand accessor for rels" do
          assert_equal "http://self", @set.links["self"]
          assert_equal "http://self", @set.links[:self]
          assert_equal "http://next", @set.links[:next]
          assert_equal nil, @set.links[:prev]
        end
      end
      
      it "returns an empty list when no links present" do
        assert_equal Roar::Representer::Feature::Hypermedia::LinkCollection.new, @bookmarks.new.links
      end
    end
  end
end

class LinksDefinitionTest < MiniTest::Spec
  describe "LinksDefinition" do
    before do
      @d = Roar::Representer::Feature::Hypermedia::LinksDefinition.new(:links)
    end
    
    it "accepts options in constructor" do
      assert_equal [], @d.rel2block
    end
    
    it "accepts configuration" do
      @d.rel2block << {:rel => :self}
      assert_equal [{:rel=>:self}], @d.rel2block
    end
    
    it "responds to #each to iterate rel2block" do
    end
    
  end
end
