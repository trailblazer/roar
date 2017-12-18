gem 'dry-types'
require 'dry-types'
require 'representable/coercion'

Types = Representable::Coercion::Types

module Roar
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
