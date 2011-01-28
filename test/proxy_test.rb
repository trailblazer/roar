require 'test_helper'

class ProxyTest < MiniTest::Spec
  describe "The public Proxy API" do
    before do
      @klass = Class.new(TestModel) do
        include Roar::Client::Proxy
        
        def self.resource_host
          "http://localhost:9999/test/"
        end
        
      end
      @o = @klass.new
    end
    
    it "#get_uri returns Restfulie response" do
      assert_equal "<test><id>4711</id></test>",  @klass.get_uri("http://localhost:9999/test/4711").body
    end
    
    it "#get returns deserialized object from " do  # DISCUSS: move to Client?
      assert_equal({"id" => "4711"},  @klass.get(4711).attributes)
    end
  end
  
  describe "EntityProxy" do
    before do
      @proxy_class = EntityProxy.class_for(:class => TestModel)
    end
    
    it ".class_for returns an EntityProxy subclass" do
      @proxy = @proxy_class.new
      assert_kind_of EntityProxy, @proxy
    end
    
    it "responds to .options" do
      assert_equal({:class => TestModel}, @proxy_class.options)
    end
    
    it "doesn't override superclass options" do
      assert_equal nil, EntityProxy.options
    end
    
    it "responds to .from_attributes and responds to #attributes" do
      assert_equal({:urn => "urn:item"}, @proxy_class.from_attributes(:urn => "urn:item").attributes)
    end
    
    it "responds to .model_name with the proxied name" do
      assert_equal "test", @proxy_class.model_name
    end
  end
end
