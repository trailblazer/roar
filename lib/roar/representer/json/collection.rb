require 'roar/representer/json'
require 'representable/json/collection'

module Roar
  module Representer
    module JSON
      module Collection
        def self.included(base)
          base.class_eval do
            include Representer
            include Representer::JSON
            include Representable::JSON
            include Representable::JSON::Collection
          end
        end
      end
    end
  end
end
