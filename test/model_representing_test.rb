require 'test_helper'
require 'roar/representer/model_representing'

class ModelRepresentingTest < MiniTest::Spec
  describe "ModelRepresenting" do
    class ItemRepresenter < Roar::Representer::Roxml
      include Roar::Representer::ModelRepresenting # TODO: move to abstract!
      xml_name :item
      xml_accessor :value
    end
    
    class PositionRepresenter < Roar::Representer::Roxml
      include Roar::Representer::ModelRepresenting # TODO: move to abstract! 
      xml_name :position
      xml_accessor :id
      xml_accessor :item, :as => ItemRepresenter
    end
    
    class OrderRepresenter < Roar::Representer::Roxml
      include Roar::Representer::ModelRepresenting # TODO: move to abstract!
      xml_name :order
      xml_accessor :id
      xml_accessor :items, :as => [ItemRepresenter]
    end
    
    describe "#definition_class" do
      it "returns ModelDefinition" do
        assert_equal Roar::Representer::ModelRepresenting::ModelDefinition, OrderRepresenter.definition_class
      end
      
    end
    
    describe "#for_model" do
      it "copies represented model attributes, nothing more" do
        @o = Position.new("id" => 1, "item" => Item.new("value" => "Beer"))
        
        @r = PositionRepresenter.for_model(@o)
        assert_kind_of PositionRepresenter, @r
        assert_equal 1, @r.id
        
        @i = @r.item
        assert_kind_of ItemRepresenter, @i
        assert_equal "Beer", @i.value
      end
      
      it "works with Hyperlink attributes" do
        @c = Class.new(ItemRepresenter) do
          link :self do "http://self" end
        end
        
        assert_equal({"value"=>"Beer", "links"=>[{"rel"=>:self, "href"=>"http://self"}]}, @c.for_model(Item.new("value" => "Beer")).to_attributes)
      end
      
    end
    
    describe "#serialize_model" do
      it "skips empty :item" do
        @o = Position.new("id" => 1)
        assert_xml_equal "<position><id>1</id></position>", PositionRepresenter.serialize_model(@o)
      end
      
      it "skips empty [:items]" do
        assert_xml_equal "<order><id>1</id></order>", OrderRepresenter.serialize_model(Order.new("id" => 1))
      end
      
      it "serializes the model" do
        @o = Order.new("id" => 1, "items" => [Item.new("value" => "Beer")])
        assert_xml_equal %{
<order>
  <id>1</id>
  <item>
    <value>Beer</value>
  </item>
</order>}"", OrderRepresenter.serialize_model(@o)
      end
      
    end
    
    
    it "Model::ActiveRecordMethods#to_nested_attributes" do
      @o = Order.new("id" => 1, "items" => [Item.new("value" => "Beer")])
      @r = OrderRepresenter.for_model(@o)
      
      OrderRepresenter.class_eval do
        include Roar::Representer::ActiveRecordMethods
      end
      assert_equal({"id" => 1, "items_attributes" => [{"value" => "Beer"}]}, @r.to_nested_attributes) # DISCUSS: overwrite #to_attributes.
    end
  end
end
