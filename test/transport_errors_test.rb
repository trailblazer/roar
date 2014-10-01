require 'test_helper'

require "roar"
require 'roar/representer/transport/errors'

class TransportErrorsTest < MiniTest::Spec

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

          klass_name = http_status_information["title"].camelize.gsub(" ","").gsub("-", "")

          expected_class = "Roar::Representer::Transport::Errors::#{klass_name}".constantize
          actual_error_class = Roar::Representer::Transport::Errors::HTTP_STATUS_TO_ERROR_MAPPINGS[http_status_code]

          assert_equal actual_error_class, expected_class, "No or incorrect error defined for error code #{http_status_code}"

        end
      end
    end
  end
end
