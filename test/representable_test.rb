require 'test_helper'
require 'roar/model/representable'

class RepresentableTest < MiniTest::Spec
  class ThisAsAppXml < Roar::Representer::Base
  end
  
  describe "Representer" do
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
    
  end
end
