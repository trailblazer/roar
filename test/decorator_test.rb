require 'test_helper'
require 'roar/decorator'

class DecoratorTest < MiniTest::Spec
  class SongRepresentation < Roar::Decorator
    include Roar::Representer::JSON

    property :name
  end

  describe "Decorator" do
    let (:song) { OpenStruct.new(:name => "Not The Same") }

    it "exposes ::prepare" do
      SongRepresentation.prepare(song).to_hash.must_equal({"name"=>"Not The Same"})
    end
  end

  describe "Hypermedia modules" do
    representer_for do
      link(:self) { "http://self" } # TODO: test with Collection::JSON, too.
    end

    let (:model) { Object.new }
    let (:model_with_links) { model.singleton_class.instance_eval { attr_accessor :links }; model }

    describe "JSON" do
      let (:decorator_class) { rpr_mod = rpr
        Class.new(Roar::Decorator) do
          include rpr_mod
        end }
      let (:decorator) { decorator_class.new(model) }

      it "rendering links works" do
        decorator.to_hash.must_equal({"links"=>[{:rel=>:self, :href=>"http://self"}]})
      end

      it "sets links on decorator" do
        decorator.from_hash("links"=>[{:rel=>:self, :href=>"http://next"}])
        decorator.links.must_equal("self"=>link(:rel=>:self, :href=>"http://next"))
      end

      it "does not set links on represented" do
        decorator_class.new(model_with_links).from_hash("links"=>[{:rel=>:self, :href=>"http://self"}])
        model_with_links.links.must_equal nil
      end

      describe "Decorator::HypermediaClient" do
        let (:decorator) { rpr_mod = rpr
          Class.new(Roar::Decorator) do
            include rpr_mod
            include Roar::Decorator::HypermediaConsumer
          end }

        it "propagates links to represented" do
          decorator.new(model_with_links).from_hash("links"=>[{:rel=>:self, :href=>"http://next"}])
          model_with_links.links[:self].must_equal(link(:rel=>:self, :href=>"http://next"))
        end
      end
    end

    describe "XML" do
      representer_for([Roar::Representer::XML, Roar::Representer::Feature::Hypermedia]) do
        link(:self) { "http://self" } # TODO: test with HAL, too.
        #self.representation_wrap = :song   # FIXME: why isn't this working?
      end
      let (:decorator_class) { rpr_mod = rpr
        Class.new(Roar::Decorator) do
          include rpr_mod
          self.representation_wrap = :song
        end
      }
      let (:decorator) { decorator_class.new(model) }

      it "rendering links works" do
        decorator.to_xml.must_equal_xml "<song><link rel=\"self\" href=\"http://self\"/></song>"
      end

      it "sets links on decorator" do
        decorator.from_xml(%{<song><link rel="self" href="http://next"/></song>})
        decorator.links.must_equal("self"=>link(:rel=>:self, :href=>"http://next"))
      end
    end


    describe "JSON::HAL" do
      representer_for([Roar::Representer::JSON::HAL]) do
        link(:self) { "http://self" }
      end
      let (:decorator_class) { rpr_mod = rpr
        Class.new(Roar::Decorator) do
          include rpr_mod
        end
      }
      let (:decorator) { decorator_class.new(model) }

      it "rendering links works" do
        decorator.to_hash.must_equal({"_links"=>{"self"=>{:href=>"http://self"}}})
      end

      it "sets links on decorator" do
        decorator.from_hash({"_links"=>{"self"=>{:href=>"http://next"}}})
        decorator.links.must_equal("self"=>link(:rel=>:self, :href=>"http://next"))
      end

      describe "Decorator::HypermediaClient" do
        let (:decorator) { rpr_mod = rpr
          Class.new(Roar::Decorator) do
            include rpr_mod
            include Roar::Decorator::HypermediaConsumer
          end }

        it "propagates links to represented" do
          decorator.new(model_with_links).from_hash("_links"=>{"self"=>{:href=>"http://self"}})
          model_with_links.links[:self].must_equal(link(:rel=>:self, :href=>"http://self"))
        end
      end
    end
  end
end
