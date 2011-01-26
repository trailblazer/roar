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
end
