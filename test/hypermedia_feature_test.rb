require 'test_helper'
require 'roar/representer/feature/hypermedia'
require 'roar/representer/json'

class HypermediaTest < MiniTest::Spec
  describe "Hypermedia Feature" do


    before do
      @bookmarks = Class.new do
        include AttributesConstructor
        include Roar::Representer::XML
        include Roar::Representer::Feature::Hypermedia

        self.representation_wrap = "bookmarks"
      end

      @bookmarks_with_links = Class.new(@bookmarks)
      @bookmarks_with_links.class_eval do
        self.representation_wrap = "bookmarks"

        property :id
        link :self do "http://bookmarks" end
        link :all do "http://bookmarks/all" end

        attr_accessor :id, :self, :all
      end
    end


    describe "#to_xml" do
      it "sets up links and renders <link> correctly in XML" do
        assert_xml_equal '<bookmarks>
                            <id>1</id>
                            <link rel="self" href="http://bookmarks"/>
                            <link rel="all" href="http://bookmarks/all"/>
                          </bookmarks>', @bookmarks_with_links.new(:id => 1).to_xml
      end

      it "still works even if there are no links defined" do
        assert_xml_equal '<bookmarks/>', @bookmarks.new.to_xml
      end

      it "doesn't render links with :links => false" do
        assert_xml_equal '<bookmarks>
                            <id>1</id>
                          </bookmarks>',
          @bookmarks_with_links.new(:id => 1).to_xml(:links => false)
      end
    end

    describe "#to_json" do
      class Note
        include Roar::Representer::JSON
        include Roar::Representer::Feature::Hypermedia
        link(:self) { "http://me" }
      end

      it "works twice" do
        note = Note.new
        assert_equal note.to_json, note.to_json
      end

      it "sets up links even when nested" do
        class Page
          include AttributesConstructor
          include Roar::Representer::JSON
          property :note, :class => Note
          attr_accessor :note
        end

        assert_equal "{\"note\":{\"links\":[{\"rel\":\"self\",\"href\":\"http://me\"}]}}", Page.new(:note => Note.new).to_json
      end
    end



    describe "#from_xml" do
      it "extracts links from document" do
        doc = @bookmarks_with_links.from_xml(%{
        <bookmarks>
          <link rel="self" href="http://bookmarks">
        </bookmarks>
        })

        assert_kind_of Roar::Representer::Feature::Hypermedia::LinkCollection, doc.links
        assert_equal 1, doc.links.size
        assert_equal(["self", "http://bookmarks"], [doc.links_array.first.rel, doc.links_array.first.href])
      end

      it "sets up an empty link list if no links found in the document" do
        assert_equal [], @bookmarks_with_links.from_xml(%{<bookmarks/>}).links_array
      end
    end


    describe "#links" do
      subject { Object.new.extend(rpr).tap do |obj|
        obj.send :prepare_links!
      end }

      representer_for do
        link(:self) { "//self" }
        link(:next) { "//next" }
      end

        it "returns link object" do
          subject.links["self"].href.must_equal "//self"
          subject.links[:self].href.must_equal "//self"
          subject.links[:next].href.must_equal "//next"
          subject.links["unknown"].must_equal nil
        end

#      it "returns an empty list when no links present" do
 #       assert_equal Roar::Representer::Feature::Hypermedia::LinkCollection.new, @bookmarks.new.links
  #    end
    end
  end
end


class LinkCollectionTest < MiniTest::Spec
  describe "LinkCollection" do
    subject { Roar::Representer::Feature::Hypermedia::LinkCollection.new }
    
    describe "#add" do
      it "keys by using rel string" do
        subject.size.must_equal 0
        subject.add(link = link(:rel => :self))
        subject.values.must_equal [link]
        subject.add(link = link(:rel => "self"))
        subject.values.must_equal [link]
      end
    end
  end
end
