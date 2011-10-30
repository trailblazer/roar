require 'test_helper'
require 'roar/representer/feature/hypermedia'

class HypermediaTest
  describe "Hypermedia Feature" do
    before do
      @bookmarks = Class.new do
        include Roar::Representer::XML
        include Roar::Representer::Feature::Hypermedia
        
        self.representation_name = "bookmarks"
      end
      
      @bookmarks_with_links = Class.new(@bookmarks)
      @bookmarks_with_links.class_eval do
        property :id
        link :self do "http://bookmarks" end
        link :all do "http://bookmarks/all" end
      end
    end
    
    
    describe "#serialize" do
      it "sets up links and renders <link> correctly in XML" do
        assert_xml_equal '<bookmarks>
                            <id>1</id>
                            <link rel="self" href="http://bookmarks"/>
                            <link rel="all" href="http://bookmarks/all"/>
                          </bookmarks>', @bookmarks_with_links.from_attributes(:id => 1).serialize
      end
      
      it "still works even if there are no links defined" do
        assert_xml_equal '<bookmarks/>', @bookmarks.new.serialize
      end
      
      it "doesn't render links with :links => false" do
        assert_xml_equal '<bookmarks>
                            <id>1</id>
                          </bookmarks>', 
          @bookmarks_with_links.from_attributes(:id => 1).serialize(:links => false)
      end
      
    end
    
    
    describe "#deserialize" do
      it "extracts links from document" do
        doc = @bookmarks_with_links.deserialize(%{
        <bookmarks>
          <link rel="self" href="http://bookmarks">
        </bookmarks>
        })
        
        assert_kind_of Roar::Representer::Feature::Hypermedia::LinkCollection, doc.links
        assert_equal 1, doc.links.size
        assert_equal({"rel"=>"self", "href"=>"http://bookmarks"}, doc.links.first.to_attributes) 
      end
      
      it "sets up an empty link list if no links found in the document" do
        assert_equal [], @bookmarks_with_links.deserialize(%{<bookmarks/>}).links
      end
    end
    
    
    describe "#links" do
      before do
        @set  = @bookmarks.new
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
    
    
    describe "#find_links_definition" do
      it "returns Definition if links are present" do
        @bookmarks.class_eval do
          property :id
          link :self
        end
        
        assert_equal "link", @bookmarks.find_links_definition.name
      end
      
      it "returns nil if no links defined" do
        assert_equal nil, @bookmarks.find_links_definition
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
