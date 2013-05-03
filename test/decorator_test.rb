require 'test_helper'

class DecoratorTest < MiniTest::Spec
  describe "Decorator" do
    it "exposes ::prepare" do
      require 'representable/version'
      if Representable::VERSION.split(".")[1] == "4"
        require 'roar/decorator'

        class SongRepresentation < Roar::Decorator
          include Roar::Representer::JSON

          property :name
        end

        SongRepresentation.prepare(OpenStruct.new(:name => "Not The Same")).to_hash.must_equal({"name"=>"Not The Same"})
      end
    end
  end

  describe "Hypermedia modules" do
    representer_for do
      link(:self) { "http://self" } # TODO: test with Collection::JSON, too.
    end

    let (:model) { Object.new }

    describe "JSON" do
      let (:decorator) { rpr_mod = rpr
        Class.new(Roar::Decorator) do
          include rpr_mod
        end }

      it "rendering links works" do
        decorator.new(model).to_hash.must_equal({"links"=>[{:rel=>:self, :href=>"http://self"}]})
      end

      it "sets links on decorator" do
        decorator.new(model).from_hash("links"=>[{:rel=>:self, :href=>"http://self"}]).links.must_equal("self"=>link(:rel=>:self, :href=>"http://self"))
      end
    end

    describe "XML" do
      representer_for([Roar::Representer::XML, Roar::Representer::Feature::Hypermedia]) do
        link(:self) { "http://self" } # TODO: test with HAL, too.
        #self.representation_wrap = :song   # FIXME: why isn't this working?
      end
      let (:decorator) { rpr_mod = rpr
        Class.new(Roar::Decorator) do
          include rpr_mod
          self.representation_wrap = :song
        end }

      it "rendering links works" do
        decorator.new(model).to_xml.must_equal_xml "<song><link rel=\"self\" href=\"http://self\"/></song>"
      end

      it "sets links on decorator" do
        decorator.new(model).from_xml(%{<song><link rel="self" href="http://self"/></song>}).links.must_equal("self"=>link(:rel=>:self, :href=>"http://self"))
      end
    end


    describe "JSON::HAL" do
      representer_for([Roar::Representer::JSON::HAL]) do
        link(:self) { "http://self" }
      end
      let (:decorator) { rpr_mod = rpr
        Class.new(Roar::Decorator) do
          include rpr_mod
        end }

      it "rendering links works" do
        decorator.new(model).to_hash.must_equal({"_links"=>{"self"=>{:href=>"http://self"}}})
      end
    end
  end
end
