require "yaml"
require "active_support/core_ext/string"

module Roar
  module Representer
    module Transport

      class Error < StandardError;

        attr_reader :http_body

        def initialize(http_body=nil)
          @http_body = http_body
        end
      end

      module Errors

        class << self

          def parse_errors
            error_mappings = http_response_mappings.delete_if { |key, value| key == "success" }

            error_mappings.inject({}) do |resulting_hash, (http_class, code_mappings)|

              code_mappings.each_pair do |http_status_code, http_status_information|

                klass      = Class.new(Roar::Representer::Transport::Error)
                klass_name = http_status_information["title"].camelize.gsub(" ","").gsub("-", "")

                Roar::Representer::Transport::Errors.const_set(klass_name, klass)

                resulting_hash[http_status_code] = klass
              end

              resulting_hash
            end
          end

          private

          def http_response_mappings
            yaml_responses = "#{Roar.root}/config/http_responses.yml"
            YAML.load(File.read(yaml_responses))
          end
        end

        HTTP_STATUS_TO_ERROR_MAPPINGS = parse_errors

      end
    end
  end
end
