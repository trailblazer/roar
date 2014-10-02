require "roar"
require "yaml"
require "active_support/core_ext/string"

module Roar
  module Representer
    module Transport

      class Error < StandardError;

        attr_reader :http_body

        class << self
          attr_reader :http_classification
        end

        def initialize(http_body=nil)
          @http_body = http_body
        end
      end

      module Errors

        class << self

          def parse_errors
            error_mappings = http_response_mappings.delete_if { |key, value| key == "success" }

            define_error_classes(error_mappings.keys)

            error_mappings.inject({}) do |resulting_hash, (http_class, code_mappings)|

              code_mappings.each_pair do |http_status_code, http_status_information|

                klass      = Class.new(Roar::Representer::Transport::Error)
                klass_name = http_status_information["title"].camelize.gsub(/(\s|-)+/, "")

                Roar::Representer::Transport::Errors.const_set(klass_name, klass)

                resulting_hash[http_status_code] = klass
              end

              resulting_hash
            end
          end

          private

          def define_error_classes(error_classes)
            error_classes.inject({}) do |error_class_mappings, error_class|

              klass = Class.new(Roar::Representer::Transport::Error)
              klass.instance_variable_set(:@http_classification, error_class.titlecase)

              klass_name = "#{error_class.gsub("error", "").camelize}Error"
              Roar::Representer::Transport::Errors.const_set(klass_name, klass)

              error_class_mappings[error_class] = klass
              error_class_mappings
            end
          end

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
