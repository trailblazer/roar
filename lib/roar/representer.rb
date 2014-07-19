require 'representable'

module Roar
  module Representer

    def self.included(base)
      super
      base.send(:include, Representable)
    end
  end
end
