require 'faraday'
require 'net/http'
require 'uri'

module MiniTest::Assertions

  def assert_headers(accept, content_type, headers)
    assert_equal [accept, content_type], [headers["Accept"], headers["Content-Type"]]
  end

  def assert_body(body, response, type)
    assert_equal "<method>#{type}#{(' - ' + body) if body}</method>", response.body
  end

  def assert_faraday_response(type, response, url, as, body = nil)
    assert_equal response.env[:url].to_s, url
    assert_headers(as, as, response.env[:request_headers])
    assert_body(body, response, type)
  end

  def assert_net_response(type, response, url, as, body = nil)
    # TODO: Assert url
    # TODO: Assert headers
    assert_body(body, response, type)
  end

end

Faraday::Response.infect_an_assertion :assert_faraday_response, :must_match_faraday_response
Net::HTTPOK.infect_an_assertion :assert_net_response, :must_match_net_response