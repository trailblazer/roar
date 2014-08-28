require 'test_helper'
require 'roar/representer/transport/net_http'
require 'spy/integration'


describe Roar::Representer::Transport::NetHTTP do

  describe "instance methods" do

    let(:url) { "http://www.bbc.co.uk" }
    let(:as) { "application/xml" }

    let(:transport) { Roar::Representer::Transport::NetHTTP.new }

    describe "options passed to the request object (private #call method)" do

      let(:options) { { uri: url, as: as, pem_file: "test/fixtures/sample.pem", ssl_verify_mode: "ssl_verify_mode" } }

      describe "option handling" do

        it "provides all options to the Request object" do

          request_mock = MiniTest::Mock.new
          request_mock.expect :call, nil, [Net::HTTP::Get]

          request_spy = Spy.on(Roar::Representer::Transport::NetHTTP::Request, new: request_mock)

          transport.get_uri(options)

          assert request_mock.verify
          assert request_spy.has_been_called?
          assert_equal 1, request_spy.calls.count
          assert(request_spy.has_been_called_with?(options), "Correct Request Options are provided")
        end
      end
    end
  end
end

