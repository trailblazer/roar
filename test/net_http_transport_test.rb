require 'test_helper'
require 'roar/representer/transport/net_http'

class NetHTTPTransportTest < MiniTest::Spec
  let(:url) { "http://localhost:4567/method" }
  let(:body) { "booty" }
  let(:as) { "application/xml" }
  before do
    @transport = Roar::Representer::Transport::NetHTTP.new
  end

  it "#get_uri returns response" do
    @transport.get_uri(url, as).must_match_net_response :get, url, as
  end

  it "#post_uri returns response" do
    @transport.post_uri(url, body, as).must_match_net_response :post, url, as, body
  end

  it "#put_uri returns response" do
    @transport.put_uri(url, body, as).must_match_net_response :put, url, as, body
  end

  it "#delete_uri returns response" do
    @transport.delete_uri(url, as).must_match_net_response :delete, url, as
  end

  it "#patch_uri returns response" do
    @transport.patch_uri(url, body, as).must_match_net_response :patch, url, as, body
  end

  it "complains with invalid URL" do
    assert_raises RuntimeError do
      @transport.get_uri("example.com", as)
    end
  end
end

module MiniTest::Assertions

  def assert_net_response(type, response, url, as, body = nil)
    # TODO: Assert headers
    assert_equal "<method>#{type}#{(' - ' + body) if body}</method>", response.body
  end

end

Net::HTTPOK.infect_an_assertion :assert_net_response, :must_match_net_response
