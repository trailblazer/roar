require 'test_helper'
require 'roar/representer/transport/net_http'

class NetHTTPTransportTest < MiniTest::Spec
  describe "Transport" do
    before do
      @transport = Roar::Representer::Transport::NetHTTP.new
    end
    
    it "#get_uri returns response" do
      assert_equal "<method>get</method>",  @transport.get_uri("http://roar.example.com/method", "application/xml").body
    end
    
    it "#post_uri returns response" do
      assert_equal "<method>post</method>",  @transport.post_uri("http://roar.example.com/method", "booty", "application/xml").body
    end
    
    it "#put_uri returns response" do
      assert_equal "<method>put</method>",  @transport.put_uri("http://roar.example.com/method", "booty", "application/xml").body
    end
    
    it "#delete_uri returns response" do
      assert_equal "<method>delete</method>",  @transport.delete_uri("http://roar.example.com/method", "application/xml").body
    end
    
    it "#patch_uri returns response" do
      assert_equal "<method>patch</method>",  @transport.patch_uri("http://roar.example.com/method", "booty", "application/xml").body
    end
  end
end
