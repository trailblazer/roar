require 'test_helper'

class HypermediaTest < MiniTest::Spec
  describe "inheritance" do
    before do
      module BaseRepresenter
        include Roar::Representer::JSON
        include Roar::Representer::Feature::Hypermedia

        link(:base) { "http://base" }
      end

      module Bar
        include Roar::Representer::JSON
        include Roar::Representer::Feature::Hypermedia

        link(:bar) { "http://bar" }
      end

      module Foo
        include Roar::Representer::JSON
        include Roar::Representer::Feature::Hypermedia
        include BaseRepresenter
        include Bar

        link(:foo) { "http://foo" }
      end
    end

    it "inherits parent links" do
      foo = Object.new.extend(Foo)

      assert_equal "{\"links\":[{\"rel\":\"base\",\"href\":\"http://base\"},{\"rel\":\"bar\",\"href\":\"http://bar\"},{\"rel\":\"foo\",\"href\":\"http://foo\"}]}", foo.to_json
    end

    it "inherits links from all mixed-in representers" do
      skip
      Object.new.extend(BaseRepresenter).extend(Bar).to_json.must_equal "{\"links\":[{\"rel\":\"base\",\"href\":\"http://base\"},{\"rel\":\"bar\",\"href\":\"http://bar\"}]}"
    end
  end

  describe "#links_array" do
    subject { Object.new.extend(rpr) }

    representer_for do
      link(:self) { "//self" }
    end


    describe "#to_json" do
      it "renders" do
        subject.to_json.must_equal "{\"links\":[{\"rel\":\"self\",\"href\":\"//self\"}]}"
      end
    end

    describe "#from_json" do
      it "parses" do
        subject.from_json "{\"links\":[{\"rel\":\"self\",\"href\":\"//self\"}]}"
        subject.links.must_equal({"self" => link(:rel => :self, :href => "//self")})
      end
    end


    describe "#link" do

      describe "with any options" do
        representer_for do
          link(:rel => :self, :title => "Hey, @myabc") { "//self" }
        end

        it "renders options" do
          subject.to_json.must_equal "{\"links\":[{\"rel\":\"self\",\"title\":\"Hey, @myabc\",\"href\":\"//self\"}]}"
        end
      end

      describe "with string rel" do
        representer_for do
          link("ns:self") { "//self" }
        end

        it "renders rel" do
          subject.to_json.must_equal "{\"links\":[{\"rel\":\"ns:self\",\"href\":\"//self\"}]}"
        end
      end

      describe "passing options to serialize" do
        representer_for do
          link(:self) { |opts| "//self/#{opts[:id]}" }
        end

        it "receives options when rendering" do
          subject.to_json(:id => 1).must_equal "{\"links\":[{\"rel\":\"self\",\"href\":\"//self/1\"}]}"
        end

        describe "in a composition" do
          representer_for do
            property :entity, :extend => self
            link(:self) { |opts| "//self/#{opts[:id]}" }
          end

          it "propagates options" do
            Song.new(:entity => Song.new).extend(rpr).to_json(:id => 1).must_equal "{\"entity\":{\"links\":[{\"rel\":\"self\",\"href\":\"//self/1\"}]},\"links\":[{\"rel\":\"self\",\"href\":\"//self/1\"}]}"
          end
        end
      end

      describe "returning option hash from block" do
        representer_for do
          link(:self) do {:href => "//self", :type => "image/jpg"} end
        end

        it "is rendered as link attributes" do
          subject.to_json.must_equal "{\"links\":[{\"rel\":\"self\",\"href\":\"//self\",\"type\":\"image/jpg\"}]}"
        end
      end

      describe "not calling #link" do
        representer_for {}

        it "still allows rendering" do
          subject.to_json.must_equal "{}"
        end
      end
    end

    # private tests:

    it "returns array of links for rendering" do
      subject.send :prepare_links!
      subject.links_array.must_equal [link(:rel => :self, :href => "//self")]
    end

    it "#links_array maps array to LinkCollection hash" do
      subject.links_array= [link(:rel => :self, :href => "//self")]
      subject.links.must_equal({"self" => link(:rel => :self, :href => "//self")})
    end
  end
end

class HyperlinkTest < MiniTest::Spec
  describe "Hyperlink" do
    subject { link(:rel => "self", "href" => "http://self", "data-whatever" => "Hey, @myabc") }

    it "accepts string keys in constructor" do
      assert_equal "Hey, @myabc", subject.send("data-whatever")
    end

    it "responds to #rel" do
      assert_equal "self", subject.rel
    end

    it "responds to #href" do
      assert_equal "http://self", subject.href
    end

    it "responds to #replace with string keys" do
      subject.replace("rel" => "next")
      assert_equal nil, subject.href
      assert_equal "next", subject.rel
    end

    it "responds to #each and implements Enumerable" do
      assert_equal ["rel:self", "href:http://self", "data-whatever:Hey, @myabc"], subject.collect { |k,v| "#{k}:#{v}" }
    end
  end

  describe "Config inheritance" do
    # TODO: this section will soon be moved to uber.
    describe "inheritance when including" do
      # TODO: test all the below issues AND if cloning works.
      module TestMethods
        def representer_for(modules=[Roar::Representer::Feature::Hypermedia, Representable], &block)
          Module.new do
            extend TestMethods
            include *modules
            module_exec(&block)
          end
        end
      end
      include TestMethods

      it "inherits to uninitialized child" do
        representer_for do # child
          include(representer_for do # parent
            representable_attrs.inheritable_array(:links) << "bar"
          end)
        end.representable_attrs.inheritable_array(:links).must_equal(["bar"])
      end

      it "works with uninitialized parent" do
        representer_for do # child
          representable_attrs.inheritable_array(:links) << "bar"

          include(representer_for do # parent
          end)
        end.representable_attrs.inheritable_array(:links).must_equal(["bar"])
      end

      it "inherits when both are initialized" do
        representer_for do # child
          representable_attrs.inheritable_array(:links) << "bar"

          include(representer_for do # parent
            representable_attrs.inheritable_array(:links) << "stadium"
          end)
        end.representable_attrs.inheritable_array(:links).must_equal(["bar", "stadium"])
      end

      it "clones parent inheritables" do # FIXME: actually we don't clone here!
        representer_for do # child
          representable_attrs.inheritable_array(:links) << "bar"

          include(parent = representer_for do # parent
            representable_attrs.inheritable_array(:links) << "stadium"
          end)

          parent.representable_attrs.inheritable_array(:links) << "park"  # modify parent array.
        
        end.representable_attrs.inheritable_array(:links).must_equal(["bar", "stadium"])
      end

      it "doesn't mess up with inheritable_array" do  # FIXME: remove this test when uber is out.
        OpenStruct.new.extend( Module.new do
                  include Roar::Representer::JSON
                  include Module.new do
                    include Roar::Representer::JSON
                    include Roar::Representer::Feature::Hypermedia
        
                    property :bla

                    link( :self) {"bo"}
                  end
                  property :blow
                end).to_json


      end
    end
  end
end
