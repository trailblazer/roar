require 'test_helper'
require 'roar/representer/feature/basic_http_transport'

class BasicHttpTransportTest < MiniTest::Spec
  describe 'BasicHttpTransport' do
    before do
      @transport = Roar::Representer::Feature::BasicHttpTransport
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
    
    # TODO: how to get PATCH into Sinatra?
    #it "#patch_uri returns Restfulie response" do
    #  assert_equal "<method>patch</method>",  @o.patch_uri("http://roar.example.com/method", "booty", "application/xml").body
    #end
  end
end
