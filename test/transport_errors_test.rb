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
            klass_name = http_status_information["title"].camelize.gsub(/(\s|-)+/, "")
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
            assert_raises(Roar::Representer::Transport::Errors::ClientErrors::NotFoundError) { request.call(http_verb) }
          end

          it "packs the original http payload into the exception" do
            begin
              request.call(http_verb)
            rescue Roar::Representer::Transport::Errors::ClientErrors::NotFoundError => e
              assert_equal e.http_body, http_body, "HTTP Exception does not contain the http payload"
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

