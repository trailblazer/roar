require 'test_helper'
require 'roar/representer/feature/model_representing'

class ModelRepresentingTest < MiniTest::Spec
  describe "ModelRepresenting" do
    class ItemRepresenter
      include Roar::Representer::XML
      include Roar::Representer::Feature::ModelRepresenting
      self.representation_wrap= :item
      property :value
    end
    
    class PositionRepresenter
      include Roar::Representer::XML
      include Roar::Representer::Feature::ModelRepresenting
      self.representation_wrap= :position
      property :id
      property :item, :as => ItemRepresenter
    end
    
    class OrderRepresenter
      include Roar::Representer::XML
      include Roar::Representer::Feature::ModelRepresenting
      self.representation_wrap= :order
      property :id
      collection :items, :as => ItemRepresenter
    end
    
    describe "#definition_class" do
      it "returns ModelDefinition" do
        assert_equal Roar::Representer::Feature::ModelRepresenting::ModelDefinition, OrderRepresenter.send(:definition_class)
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
      
      it "references the model in @represented" do
        @o = Position.new("id" => 1, "item" => @i = Item.new("value" => "Beer"))
        
        @r = PositionRepresenter.for_model(@o)
        assert_equal @o, @r.represented
        assert_equal @i, @r.item.represented
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
    
    describe "#to_nested_attributes" do
      it "provides a AR-compatible hash" do
        @o = Order.new("id" => 1, "items" => [Item.new("value" => "Beer")])
        @r = OrderRepresenter.for_model(@o)
        
        OrderRepresenter.class_eval do
          include Roar::Representer::Feature::ActiveRecordMethods
        end
        ItemRepresenter.class_eval do
          include Roar::Representer::Feature::ActiveRecordMethods
        end
        assert_equal({"id" => 1, "items_attributes" => [{"value" => "Beer"}]}, @r.to_nested_attributes) # DISCUSS: overwrite #to_attributes.
      end
      
      it "doesn't include :links" do
        @o = Order.new("id" => 1, "items" => [Item.new("value" => "Beer")])
        
        
        
        OrderRepresenter.class_eval do
          include Roar::Representer::Feature::ActiveRecordMethods
          include Roar::Representer::Feature::Hypermedia
          link :self do
        #    "bla"
          end
        end
        ItemRepresenter.class_eval do
          include Roar::Representer::Feature::ActiveRecordMethods
          include Roar::Representer::Feature::Hypermedia
          link :self do
            
          end
        end
        @r = OrderRepresenter.for_model(@o)
        
        assert_equal({"id" => 1, "items_attributes" => [{"value" => "Beer"}]}, @r.to_nested_attributes) # DISCUSS: overwrite #to_attributes.
      end
    end
  end
end
