require 'test_helper'

class DecoratorTest < MiniTest::Spec


  describe "Decorator" do
    it "exposes ::prepare" do
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
end
