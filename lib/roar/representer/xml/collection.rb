require 'roar/representer/xml'
require 'representable/xml/collection'

module Roar
  module Representer
    module XML
      module Collection
        def self.included(base)
          base.class_eval do
            include Representer
            include Representer::XML
            include Representable::XML
            include Representable::XML::Collection
          end
        end
      end
    end
  end
end
