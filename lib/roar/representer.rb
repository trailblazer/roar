require 'representable'

module Roar
  module Representer
    def self.included(base)
      base.class_eval do
        include Representable
      end
    end
    
  private
    def before_serialize(*)
    end
  end
end
