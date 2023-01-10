gem "dry-types", ">= 1.0.0"
require "dry-types"
require "representable/coercion"

module Roar
  Types = Representable::Coercion::Types

  # Use the +:type+ option to specify the conversion type.
  # class ImmigrantSong
  #   include Roar::JSON
  #   include Roar::Coercion
  #
  #   property :composed_at, :type => DateTime, :default => "May 12th, 2012"
  # end
  module Coercion
    def self.included(base)
      base.class_eval do
        include Representable::Coercion
      end
    end
  end
end
