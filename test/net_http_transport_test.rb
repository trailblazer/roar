require 'test_helper'
require 'roar/representer/transport/net_http'

class NetHTTPTransportTest < MiniTest::Spec
  let(:url) { "http://localhost:4567/method" }
  let(:body) { "booty" }
  let(:as) { "application/xml" }
  let (:transport) { Roar::Representer::Transport::NetHTTP.new }

  it "#get_uri returns response" do
    transport.get_uri(url, as).must_match_net_response :get, url, as
  end

  it "#post_uri returns response" do
    transport.post_uri(url, body, as).must_match_net_response :post, url, as, body
  end

  it "#put_uri returns response" do
    transport.put_uri(url, body, as).must_match_net_response :put, url, as, body
  end

  it "#delete_uri returns response" do
    transport.delete_uri(url, as).must_match_net_response :delete, url, as
  end

  it "#patch_uri returns response" do
    transport.patch_uri(url, body, as).must_match_net_response :patch, url, as, body
  end

  it "complains with invalid URL" do
    assert_raises RuntimeError do
      transport.get_uri("example.com", as)
    end
  end

  # TODO: test all verbs.
  describe "request customization" do
    #verbs do |verb|
    verb = "get"
      it "#{verb} yields the request object" do
        transport.send("#{verb}_uri", "http://localhost:4567/cookies", "application/json") do |req|
          req.add_field("Cookie", "Yumyum")
        end.body.must_equal %{{"name": "Bodyjar"}}
      end
    #end
  end

  describe "basic auth" do
    it "raises when no credentials provided" do
      assert_raises Roar::Representer::Transport::UnauthorizedError do
        transport.get_uri("http://localhost:4567/protected/bands/bodyjar", "application/json")
      end
    end

    it "raises when wrong credentials provided" do
      assert_raises Roar::Representer::Transport::UnauthorizedError do
        transport.get_uri("http://localhost:4567/protected/bands/bodyjar", "application/json", :basic_auth => ["admin", "wrong--!!!--password"])
      end
    end

    it "what" do
      transport.get_uri("http://localhost:4567/protected/bands/bodyjar", "application/json", :basic_auth => ["admin", "password"])
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
