require 'test_helper'

require "roar"
require 'roar/representer/transport/errors'


require 'rspec/mocks'

module MinitestRSpecMocksIntegration
  include ::RSpec::Mocks::ExampleMethods

  def before_setup
    ::RSpec::Mocks.setup
    super
  end

  def after_teardown
    super
    ::RSpec::Mocks.verify
  ensure
    ::RSpec::Mocks.teardown
  end
end

Minitest::Test.send(:include, MinitestRSpecMocksIntegration)


class TransportErrorsTest < MiniTest::Spec

  describe Roar::Representer::Transport::Error do

    describe "instance methods" do

      describe "#initialize" do

        let(:error) { Roar::Representer::Transport::Error.new(:http_body) }

        it "accepts and sets a http_body" do
          assert_equal error.http_body, :http_body, " Roar::Representer::Transport::Error did not accept a http_body on initialisation"
        end
      end
    end
  end


  describe Roar::Representer::Transport::Errors do

    describe "errors instantiation" do

      let(:http_response_mappings) do
        yaml_responses = "#{Roar.root}/config/http_responses.yml"
        YAML.load(File.read(yaml_responses))
      end

      let(:http_status_codes) do
        http_response_mappings.inject({}) do |resulting_http_status_codes, (http_class, http_status_codes)|
          resulting_http_status_codes = resulting_http_status_codes.merge(http_status_codes) unless http_class == "success"
          resulting_http_status_codes
        end
      end

      it "created an error class for each http status code" do

        http_status_codes.each_pair do |http_status_code, http_status_information|

          klass_name = http_status_information["title"].camelize.gsub(" ", "").gsub("-", "")

          expected_class     = "Roar::Representer::Transport::Errors::#{klass_name}".constantize
          actual_error_class = Roar::Representer::Transport::Errors::HTTP_STATUS_TO_ERROR_MAPPINGS[http_status_code]

          assert_equal actual_error_class, expected_class, "No or incorrect error defined for error code #{http_status_code}"
        end
      end
    end
  end

  describe Roar::Representer::Transport::NetHTTP::Request do

    describe "instance methods" do

      describe "#call" do

        let(:options) { { uri: "http://www.bbc.co.uk", as: "application/json" } }
        let(:request) { Roar::Representer::Transport::NetHTTP::Request.new(options) }
        let(:http_verb) { Net::HTTP::Get }

        let(:http_code) { 404 }
        let(:http_body) { "The Quick Brown Fox Jumped Over the Lazy Frog?" }

        let(:http_response) { double(code: 404, body: http_body) }

        let(:call_result) { request.call(http_verb) }

        let(:net_http_instance) { double(Net::HTTP, request: http_response) }

        before(:each) do
          allow(Net::HTTP).to receive(:new).and_return(net_http_instance)
        end

        it "raises a http error if a none 200 status is returned" do
          assert_raises(Roar::Representer::Transport::Errors::NotFound) { request.call(http_verb) }
        end

        it "packs the original http payload into the exception" do
          begin
            request.call(http_verb)
          rescue Roar::Representer::Transport::Errors::NotFound => e
            assert_equal e.http_body, http_body, "HTTP Exception does not contain the http payload"
          end
        end
      end
    end
  end
end
