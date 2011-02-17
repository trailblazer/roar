require 'test_helper'

require "test_xml/mini_test"
require "roxml"


module Roar
  module Representer
    class Roxml < Base
      include ROXML
      
      def serialize(attributes)
        attributes.each do |k,v|  # TODO: use roxml?
          send("#{k}=", v) and next unless k=="item"
          self.item= ItemApplicationXml.new(v)
        end
        
        to_xml.serialize
      end
      
      def deserialize(body)

      end
      
      class << self
        def has_one(attr_name, options={})
          if options[:class] 
            options[:as] = options.delete(:class) 
            #options[:to_xml] = Proc.new{|instance| instance and instance.to("application/xml")}
          end
          
          xml_accessor attr_name, options
        end
        
      end
      
    end
  end
end

class ItemApplicationXml < Roar::Representer::Roxml
  def initialize(represented)
        @represented = represented
      end
      def to_xml(*args)
        @represented.to_xml(*args)
      end
      
end

class ItemRoxmlRepresenterFunctionalTest < MiniTest::Spec
  it "subject" do
    assert_equal "expected", ItemApplicationXml.new()
  end
  
end 

class RoxmlRepresenterFunctionalTest < MiniTest::Spec
  
  class Item
    include ROXML
    
    xml_accessor :value
    
    #attr_reader :value
    
    def initialize(value)
      @value = value
    end
    
    def to(mime_type)
      raise unless mime_type == "application/xml"
      self  # ROXML expects self!
    end
    
    def self.from(mime_type, string)
      raise unless mime_type == "ruby/serialized"
      new Marshal.load(string)
    end
    
    
    
    
    def ==(b)
      value == b.value
    end
  end
  
  describe "RoxmlRepresenter" do
    before do
      @r = Class.new(Roar::Representer::Roxml).new("application/xml")
      @r.class.instance_eval do
        xml_name :test  # FIXME: move to subclass.
        has_one :id
      end
      
      @m = {:id => 1}
    end
    
    describe "without options" do
      it "#serialize returns the serialized model" do
        assert_match_xml "<test><id>1</id></test>", @r.serialize(@m)
      end
      
      it "#deserialize returns the attributes" do
        assert_equal @m, @r.deserialize("\x04\b{\x06:\aidi\x06")
      end
    end
    
    
    describe "has_one" do
      before do
        @r.class.instance_eval do
          has_one :item, :class => Item
        end
      end
      
      it "#serialize skips empty :item" do
        assert_match_xml "<test><id>1</id></test>", @r.serialize(@m)
      end
      
      it "#serialize delegates to item#to" do
        @m = {:id => 1, "item" => Item.new("beer")}
        assert_equal "<test>\n  <id>1</id>\n  <item>\n    <value>beer</value>\n  </item>\n</test>", @r.serialize(@m)
      end
      
      it "#deserialize typecasts :item" do
        m = @r.deserialize("\x04\b{\a:\aidi\x06I\"\titem\x06:\x06EF\"\x13\x04\bI\"\tbeer\x06:\x06EF")
        assert_equal({:id => 1, "item" => Item.new("beer")}, m)
      end
      
    end
  end
end
