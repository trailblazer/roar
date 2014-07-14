require 'representable'

module Roar
  module Representer

    def self.included(base)
      super
      base.send(:include, Representable)
    end

  private
    def before_serialize(*)
    end
  end
end
