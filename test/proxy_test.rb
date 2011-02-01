require 'test_helper'

class ProxyTest < MiniTest::Spec
  describe "Transport" do
    before do
      @klass = Class.new(Object) do
        include Roar::Client::Transport
      end
      @o = @klass.new
    end
    
    it "#get_uri returns Restfulie response" do
      assert_equal "<test><id>4711</id></test>",  @o.get_uri("http://localhost:9999/test/4711").body
    end
    
  end
  
  
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
    
    # DISCUSS: ḿove .get to ActiveResourceLikeModelMethods ?
    it "#get returns deserialized object from " do  # DISCUSS: move to Client?
      assert_equal({"id" => "4711"},  @klass.get(4711).attributes)
    end
    
    it "responds to .get_model" do
      @o = @klass.get_model("http://localhost:9999/test/1", TestModel)
      assert_kind_of TestModel, @o
      assert_equal({"id" => "1"}, @o.attributes)
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
    
    it "responds to .from_attributes and responds to #original_attributes" do
      assert_equal({:urn => "urn:item"}, @proxy_class.from_attributes(:urn => "urn:item").send(:original_attributes))
    end
    
    it "responds to .model_name with the proxied name" do
      assert_equal "test", @proxy_class.model_name
    end
    
    # finalize!
    describe "#finalize!" do
      before do
        @o = @proxy_class.from_attributes("uri" => "http://localhost:9999/test/1")
      end
      
      it "responds to #proxied_resource" do
        assert_nil @o.send(:proxied_resource)
      end
      
      it "#finalize! retrieves proxied resource" do
        @o.finalize!
        assert_kind_of TestModel, @o.send(:proxied_resource)
      end
      
      # delegation:
      it "#attributes are delegated" do
        @o.finalize!
        assert_equal({"id" => "1"}, @o.attributes)
      end
      
      it "#to_xml renders the unproxied entity" do
        assert_equal "<test>\n  <uri>http://localhost:9999/test/1</uri>\n</test>\n", @o.to_xml
      end
      
      it "#attributes_for_xml returns the unfinalized EntityProxy#attributes hash" do
        assert_equal({"uri"=>"http://localhost:9999/test/1"}, @o.attributes_for_xml)
      end
    end
  end
end
