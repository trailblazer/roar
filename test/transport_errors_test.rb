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

        let(:error) { Roar::Representer::Transport::Error.new(http_payload, :request, :response) }
        let(:http_payload) { { body: :http_body, status_code: :http_status_code, version: :http_version, headers: :headers } }

        describe "http payload abstraction" do
          it "accepts and sets a http_body" do
            assert_equal :http_body, error.http_body, " Roar::Representer::Transport::Error did not accept a http_body on initialisation"
          end

          it "accepts and sets a http_status_code" do
            assert_equal :http_status_code, error.http_status_code, " Roar::Representer::Transport::Error did not accept a http_status_code on initialisation"
          end

          it "accepts and sets a http_version" do
            assert_equal :http_version, error.http_version, " Roar::Representer::Transport::Error did not accept a http_version on initialisation"
          end

          it "accepts and sets headers" do
            assert_equal :headers, error.http_headers, " Roar::Representer::Transport::Error did not accept a headers on initialisation"
          end
        end

        it "accepts and sets the original request" do
          assert_equal :request, error.original_request, " Roar::Representer::Transport::Error did not accept a the original request on initialisation"
        end

        it "accepts and sets the original upstream response" do
          assert_equal :response, error.original_response, " Roar::Representer::Transport::Error did not accept a the original response on initialisation"
        end
      end
    end
  end


  describe Roar::Representer::Transport::Errors do

    @@http_status_codes = YAML.load(File.read("#{Roar.root}/config/http_responses.yml"))
    @@http_status_codes.delete_if { |http_classification, _| http_classification == "success" }.each_pair do |http_classification, http_status_codes|

      describe "#{http_classification.humanize} base error and module" do

        let(:expected_module_name) { "#{http_classification.gsub("error", "").camelize}Errors" }

        it "defined a #{http_classification.humanize} module" do
          begin
            defined_module = Roar::Representer::Transport::Errors.const_get(expected_module_name)
            assert_equal defined_module.class, Module, "Roar::Representer::Transport::Errors::#{expected_module_name} not defined as a module"
          rescue NameError
            assert false, "no module defined for #{http_classification.humanize}"
          end
        end

        it "defined a #{http_classification.humanize} error class" do

          klass = "Roar::Representer::Transport::Errors::#{http_classification.gsub("error", "").camelize}Error".constantize
          assert defined?(klass), "no error class for #{http_classification.humanize}"
        end
      end

      describe "#{http_classification.humanize} errors" do

        http_status_codes.each_pair do |http_status_code, http_status_information|

          let(:expected_module_name) { "#{http_classification.gsub("error", "").camelize}Errors" }

          it "defines an error for status code #{http_status_code}" do
            klass_name         = http_status_information["title"].camelize.gsub(/(\s|-)+/, "")
            expected_class     = "Roar::Representer::Transport::Errors::#{expected_module_name}::#{klass_name}Error".constantize
            actual_error_class = Roar::Representer::Transport::Errors::HTTP_STATUS_TO_ERROR_MAPPINGS[http_status_code]

            assert_equal actual_error_class, expected_class, "No or incorrect error defined for error code #{http_status_code}"
          end
        end
      end
    end

    describe Roar::Representer::Transport::NetHTTP::Request do

      describe "instance methods" do

        describe "#call" do

          let(:options) { { uri: uri, as: "application/json" } }
          let(:uri) { "http://www.bbc.co.uk" }

          let(:request) { Roar::Representer::Transport::NetHTTP::Request.new(options) }
          let(:http_verb) { Net::HTTP::Get }
          let(:http_request) { Net::HTTP::Get.new(URI(uri).request_uri) }

          let(:http_status_code) { 404 }
          let(:http_body) { "The Quick Brown Fox Jumped Over the Lazy Frog?" }
          let(:http_version) { "1" }
          let(:http_headers) { { "server" => ["Apache"], "content-type" => ["text/html"], "content-language" => ["en-GB"] } }


          let(:http_response) do
            double(Net::HTTPResponse,
                   code:         http_status_code,
                   body:         http_body,
                   http_version: http_version,
                   to_hash:      http_headers
            )
          end

          let(:call_result) { request.call(http_verb) }

          let(:net_http_instance) { double(Net::HTTP, request: http_response) }

          before(:each) do
            allow(Net::HTTP).to receive(:new).and_return(net_http_instance)
            allow(http_verb).to receive(:new).and_return(http_request)
          end

          it "raises a http error if a none 200 status is returned" do
            assert_raises(Roar::Representer::Transport::Errors::ClientErrors::NotFoundError) { request.call(http_verb) }
          end

          describe "http payload abstraction" do
            it "packs the original http payload into the exception" do
              begin
                request.call(http_verb)
              rescue Roar::Representer::Transport::Errors::ClientErrors::NotFoundError => e
                assert_equal e.http_body, http_body, "HTTP Exception does not contain the http payload"
              end
            end

            it "packs the original http status code into the exception" do
              begin
                request.call(http_verb)
              rescue Roar::Representer::Transport::Errors::ClientErrors::NotFoundError => e
                assert_equal http_status_code, e.http_status_code, "HTTP Exception does not contain the http status code"
              end
            end

            it "packs the original http version supported by the server into the exception" do
              begin
                request.call(http_verb)
              rescue Roar::Representer::Transport::Errors::ClientErrors::NotFoundError => e
                assert_equal http_version, e.http_version, "HTTP Exception does not contain the http version supported by the server"
              end
            end

            it "packs the original http headers into the exception" do
              begin
                request.call(http_verb)
              rescue Roar::Representer::Transport::Errors::ClientErrors::NotFoundError => e
                assert_equal http_headers, e.http_headers, "HTTP Exception does not contain the http headers"
              end
            end
          end

          it "packs the original request" do
            begin
              request.call(http_verb)
            rescue Roar::Representer::Transport::Errors::ClientErrors::NotFoundError => e
              assert_equal http_request, e.original_request, "HTTP Exception does not contain the original request"
            end
          end

          it "packs the original upstream response" do
            begin
              request.call(http_verb)
            rescue Roar::Representer::Transport::Errors::ClientErrors::NotFoundError => e
              assert_equal http_response, e.original_response, "HTTP Exception does not contain the original request"
            end
          end
        end
      end
    end

    describe "net http integration" do

      let (:transport) { Roar::Representer::Transport::NetHTTP.new }

      it 'raises a NotFoundError when a 404 status is returned' do
        assert_raises Roar::Representer::Transport::Errors::ClientErrors::NotFoundError do
          transport.get_uri(:uri => "http://localhost:4567/not_found", :as => "application/json")
        end
      end
    end
  end
end

