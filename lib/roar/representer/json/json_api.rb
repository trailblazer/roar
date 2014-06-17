require 'roar/representer/json'

module Roar::Representer::JSON
  module JsonApi
    def self.included(base)
      base.class_eval do
        include Roar::Representer::JSON
        extend ClassMethods
      end
    end
  end

  module ClassMethods
    def link(resource)

    end
  end
end
