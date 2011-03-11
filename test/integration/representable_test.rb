require 'test_helper'

class TestModel
  def self.from(mime_type, body)  # CDI approach. might be too slow to create an anonymous class for each instance! # DISCUSS.
    Class.new(self) do
      include Roar::Representer::Xml
      
      def self.from_attributes(attributes)
        superclass.new(attributes)
      end
        
    end.from_xml(body)  # DISCUSS: call this .from_body ?
  end
  
end


class RepresentableIntegrationTest < MiniTest::Spec
  describe ".from" do
    before do
      @t = TestModel.from("application/xml", "<test><id>1</id></test>")
    end
    
    it "returns a TestModel instance" do
      assert_instance_of TestModel, @t
    end
    
    it "reponds to .from" do
      assert_equal({"id" => "1"}, @t.attributes)
    end
    
  end
end
