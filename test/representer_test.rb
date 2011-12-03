require 'test_helper'

class RepresenterTest < MiniTest::Spec
  describe "Representer::Base" do
    before do
      @c = Class.new do
        include Roar::Representer::Base
      end
    end
    
    it "aliases #representable_property to #property" do
      @c.property :title
      assert_equal "title", @c.representable_attrs.first.name
    end
    
    it "aliases #representable_collection to #collection" do
      @c.collection :songs
      assert_equal "songs", @c.representable_attrs.first.name
    end
    
    
    describe "#from_attributes" do
      it "accepts a block yielding the created representer instance" do
        @c.class_eval { attr_accessor :name }
        
        assert_equal("Conan", @c.from_attributes({}) { |rep| rep.name = "Conan" }.name)
      end
      
      it "copies known properties, only, but doesn't complain" do
        @c.class_eval { property :id }
        
        assert_equal 1, @c.from_attributes("id" => 1, "unknown" => "don't use me").id
      end
      
      it "accepts symbols and strings as property name" do
        @c.class_eval { property :id }
        
        assert_equal @c.from_attributes(:id => 1).id, @c.from_attributes("id" => 1).id
      end
    end
  end
  
  describe "Inheritance" do
    it "properly inherits properties from modules" do
      module PersonRepresentation
        include Roar::Representer::JSON
        property :name
      end
      
      class Person
        include Roar::Representer::JSON
        include PersonRepresentation
      end
      
      assert_equal "{\"name\":\"Paulo\"}", Person.from_attributes(:name => "Paulo").to_json
    end
    
  end
end
