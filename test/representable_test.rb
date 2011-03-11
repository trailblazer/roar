require 'test_helper'
require 'roar/model/representable'

class RepresentableTest < MiniTest::Spec
  
  class ThisAsAppXml < Roar::Representer::Base
    def self.deserialize(represented_class, mime_type, data)
      "#{represented_class.name}->#{mime_type}: #{data}"
    end
    
    def serialize(represented, mime_type)
      "#{represented.class.name}->#{mime_type}"
    end
  end
  
  describe "Representable" do
    before do
      @c = Class.new do
        include Roar::Model::Representable
        
        represents "application/xml", :with => ThisAsAppXml
      end
    end
    
    
    describe ".representer_class_for" do
      it "returns the class" do
        assert_equal ThisAsAppXml, @c.representer_class_for("application/xml")
      end
      
      it "returns nil if unknown" do
        assert_equal nil, @c.representer_class_for("text/html")
      end
    end
    
    
    describe ".from" do
      it "receives mime_type and content" do
        assert_equal "->application/xml: <xml/>", @c.from("application/xml", "<xml/>")
      end
    end
    
    describe "#to" do
      it "receives mime_type" do
        assert_equal "->application/xml", @c.new.to("application/xml")
      end
    end
  end
end
