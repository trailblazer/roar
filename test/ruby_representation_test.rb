require File.expand_path(File.dirname(__FILE__) + '/test_helper')

module Roar
  module Representer
    class Ruby < Base
      def serialize(attributes)
        serializable_attributes = attributes.dup
        
        serialize_typed_attributes(serializable_attributes)
        Marshal.dump serializable_attributes
      end
      
      def deserialize(body)
        deserialized_hash = Marshal.load body
        deserialize_typed_attributes(deserialized_hash)
      end
      
      
      
      module ConfigurationDsl # FIXME: move to Representer::BaseDsl or so.
        def has_many(name, options={})
          collections[name] = options
        end
        alias_method :collection, :has_many
        
        def has_one(name, options={})
          typed_entities[name] = options
        end
        
        def has_proxied(name, options={})
          has_one(name, {:class => EntityProxy.class_for(options)}) 
        end
        
        def has_many_proxied(name, options={})
          has_many(name, {:class => EntityProxy.class_for(options)}) 
        end
      end
      
      self.extend ConfigurationDsl
      # FIXME: use one variable?
      extend Hooks::InheritableAttribute
      inheritable_attr :collections
      self.collections = {}
      inheritable_attr :typed_entities
      self.typed_entities = {}
      
      
      
      def serialize_typed_attributes(attributes)
          filter_attributes_for(attributes, self.class.typed_entities) do |name, options|
            next unless entity = attributes[name]
            attributes[name] = entity.to(mime_type)
          end
        end
      
      # Attributes can be typecasted with +has_one+.
        def deserialize_typed_attributes(attributes)
          filter_attributes_for(attributes, self.class.typed_entities) do |name, options|
            item  = attributes.delete(name)                        # attributes[:sum]
            item  = options[:class].from(mime_type, item) # Sum.from_xml_attributes
            attributes[name] = item
          end
        end
        
        def filter_attributes_for(attributes, config)
          config.each do |name, options|
            name = name.to_s
            yield name, options
          end
          attributes
        end
      
    end
    
    
  end
  
end


class RubyRepresenterFunctionalTest < MiniTest::Spec
  class Item
    attr_reader :value
    
    def initialize(value)
      @value = value
    end
    
    def to(mime_type)
      raise unless mime_type == "ruby/serialized"
      Marshal.dump(@value)
    end
    
    def self.from(mime_type, string)
      raise unless mime_type == "ruby/serialized"
      new Marshal.load(string)
    end
    
    def ==(b)
      value == b.value
    end
  end
  
  describe "RubyRepresenter" do
    before do
      @r = Class.new(Roar::Representer::Ruby).new("ruby/serialized")
      @m = {:id => 1}
    end
    
    describe "without options" do
      it "#serialize returns the serialized model" do
        assert_equal "\x04\b{\x06:\aidi\x06", @r.serialize(@m)
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
        assert_equal "\x04\b{\x06:\aidi\x06", @r.serialize(@m)
      end
      
      it "#serialize delegates to item#to" do
        @m = {:id => 1, "item" => Item.new("beer")}
        assert_equal "\x04\b{\a:\aidi\x06I\"\titem\x06:\x06EF\"\x13\x04\bI\"\tbeer\x06:\x06EF", @r.serialize(@m)
      end
      
      it "#deserialize typecasts :item" do
        m = @r.deserialize("\x04\b{\a:\aidi\x06I\"\titem\x06:\x06EF\"\x13\x04\bI\"\tbeer\x06:\x06EF")
        assert_equal({:id => 1, "item" => Item.new("beer")}, m)
      end
      
    end
  end
end
