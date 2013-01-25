require 'ostruct'
require 'test_helper'
require 'roar/representer/json/hal'


class HalLinkTest < MiniTest::Spec
  let(:rpr) do
    Module.new do
      include Roar::Representer::JSON
      include Roar::Representer::JSON::HAL::Links
      link :self do
        "me"
      end
    end
  end

  subject { Object.new.extend(rpr) }

  describe "#prepare_links!" do
    it "should use 'links' key" do
      assert_equal subject.to_json, "{\"links\":{\"self\":{\"href\":\"me\"}}}"
      puts subject.to_json
    end
  end
end

