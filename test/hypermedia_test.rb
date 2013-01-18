require 'test_helper'

class HypermediaTest < MiniTest::Spec
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

      describe "passing options to serialize" do
        representer_for do
          link(:self) { |opts| "//self/#{opts[:id]}" }
        end

        it "receives options when rendering" do
          subject.to_json(:id => 1).must_equal "{\"links\":[{\"rel\":\"self\",\"href\":\"//self/1\"}]}"
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
          subject.to_json.must_equal "{\"links\":[]}"
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

class LinksDefinitionTest < MiniTest::Spec
  describe "LinksDefinition" do
    subject { Roar::Representer::Feature::Hypermedia::LinksDefinition.new(:links) }

    it "responds to #<<" do
      subject << "arbitrary bullshit"
      subject.to_a.must_equal ["arbitrary bullshit"]
    end

    it "responds to #each" do
      subject.to_a.must_equal []
    end

    it "accepts options in constructor" do
      assert_equal [], subject.rel2block
    end

    it "accepts configuration" do
      subject.rel2block << {:rel => :self}
      assert_equal [{:rel=>:self}], subject.rel2block
    end

    it "responds to #clone" do
      subject.rel2block << {:rel => :self}
      assert subject.clone.rel2block.object_id != subject.rel2block.object_id
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
end
