require 'test_helper'

require "test_xml/mini_test"
require "roxml"


module Roar
  module Representer
    class Roxml < Base
      include ROXML
      
      def serialize(attributes)
        to_xml.serialize
      end
      
      def to_xml(*)
        represented.attributes.each do |k,v|  # FIXME: replace with xml_attributes from roxml.
          send("#{k}=", v)
        end
        
        # FIXME: generic model->representer.
        self.class.roxml_attrs.each { |attr| 
          #puts attr.sought_type.inspect
        
          if attr.name == "item"
            v = represented.send(:item)
            
            self.item= RoxmlRepresenterFunctionalTest::ItemApplicationXml.new(v) if v
          end
        }
        
        super
      end
      
      
      
      
      
      def deserialize(body)
        representer = self.class.from_xml(body, "application/xml")
        
        attributes = {}
        representer.roxml_references.collect do |a|
          attributes[a.name] = representer.send(a.name)
        end
        attributes
      end
      
      class << self
        def from_xml(data, *initialization_args)    # overwritten from roxml.
        xml = ROXML::XML::Node.from(data)
        
        config = roxml_attrs.collect { |attr| attr.to_ref(nil, self) }  # FIXME: see Definition#initialize
        
        represented = represented_class.new(*initialization_args) # DISCUSS: *args useful?
        
        
        config.each do |ref|
          value = ref.value_in(xml)
          represented.respond_to?(ref.opts.setter) \
              ? represented.send(ref.opts.setter, value) \
              : represented.instance_variable_set(ref.opts.instance_variable_name, value)
        end
        
        represented
      end
      
      
      
        def has_one(attr_name, options={})
          if options[:class] 
          options.delete(:class)
            options[:as] = RoxmlRepresenterFunctionalTest::ItemApplicationXml#options.delete(:class) 
            #options[:to_xml] = Proc.new{|instance| instance and instance.to("application/xml")}
          end
          
          xml_accessor attr_name, options
        end
        
      end
      
    end
  end
end



class RoxmlRepresenterFunctionalTest < MiniTest::Spec
  
  class Item < TestModel
    def value=(value)
      @attributes[:value] = value
    end
  end
  
  class ItemApplicationXml < Roar::Representer::Roxml
    self.represented_class = Item
    
    xml_accessor :value
  end
  
  describe "RoxmlRepresenter" do
    before do
      @m = {"id" => "1"}
      @o = TestModel.new(@m)
      
      @r = Class.new(Roar::Representer::Roxml).new(@o)
      @r.class.instance_eval do
        puts "setting in #{self}"
        
        
        xml_name :test  # FIXME: move to subclass.
        has_one :id
      end
      @r.class.represented_class= TestModel
    end
    
    describe "without options" do
      it "#serialize returns the serialized model" do
        assert_exactly_match_xml "<test><id>1</id></test>", @r.serialize(@m)
      end
      
      it ".from_xml returns the deserialized model" do
        assert_equal TestModel.new("id" => "1"), @r.class.from_xml("<test><id>1</id></test>")
      end
      
      it "#to_xml returns the serialized xml" do
        assert_exactly_match_xml "<test><id>1</id></test>", @r.serialize(@m)
      end
      
    end
    
    
    describe "has_one" do
      before do
        @r.class.instance_eval do
          has_one :item, :class => Item
        end
        
        
        @o.instance_eval do
          def item; attributes[:item]; end
          def item=(item); attributes[:item]=item; end
        end
        
      end
      
      it "#to_xml skips empty :item" do
        assert_exactly_match_xml "<test><id>1</id></test>", @r.to_xml.serialize
      end
      
      it "#to_xml delegates to ItemXmlRepresenter#to_xml" do
        @o.item = Item.new(:value => "Bier")
        assert_exactly_match_xml "<test><id>1</id><item><value>Bier</value></item>\n</test>", @r.to_xml.serialize
      end
      
      it ".from_xml typecasts :item" do
        m = @r.class.from_xml("<test><id>1</id><item><value>beer</value></item>\n</test>")
        assert_equal(TestModel.new("id" => "1", "item" => Item.new(:value => "beer")), m)
      end
      
    end
  end
end
