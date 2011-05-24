require 'test_helper'
require 'roar/client/transport'

class TransportTest < MiniTest::Spec
  describe "Transport" do
    before do
      @klass = Class.new(Object) do
        include Roar::Client::Transport
      end
      @o = @klass.new
    end
    
    it "#get_uri returns Restfulie response" do
      assert_equal "<method>get</method>",  @o.get_uri("http://localhost:9999/method", "application/xml").body
    end
    
    it "#post_uri returns Restfulie response" do
      assert_equal "<method>post</method>",  @o.post_uri("http://localhost:9999/method", "booty", "application/xml").body
    end
    
    it "#put_uri returns Restfulie response" do
      assert_equal "<method>put</method>",  @o.put_uri("http://localhost:9999/method", "booty", "application/xml").body
    end
    
    it "#delete_uri returns Restfulie response" do
      assert_equal "<method>delete</method>",  @o.delete_uri("http://localhost:9999/method", "application/xml").body
    end
    
    # TODO: how to get PATCH into Sinatra?
    #it "#patch_uri returns Restfulie response" do
    #  assert_equal "<method>patch</method>",  @o.patch_uri("http://localhost:9999/method", "booty", "application/xml").body
    #end
  end
end
