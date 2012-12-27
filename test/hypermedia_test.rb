require 'test_helper'

class HypermediaTest < MiniTest::Spec
  describe "#links_array" do
    let (:rpr) do
      Module.new do
        include Roar::Representer::JSON
        include Roar::Representer::Feature::Hypermedia

        link(:self) { "//self" }
      end
    end

    subject { Object.new.extend(rpr) }

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