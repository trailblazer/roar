require 'virtus'
require 'representable/coercion'

module Roar::Representer::Feature
  # Use the +:type+ option to specify the conversion type.
  # class ImmigrantSong
  #   include Roar::Representer::JSON
  #   include Roar::Representer::Feature::Coercion
  #   
  #   property :composed_at, :type => DateTime, :default => "May 12th, 2012"
  # end
  module Coercion
    def self.included(base)
      base.class_eval do
        include Virtus
        extend Representable::Coercion::ClassMethods
      end
    end
  end
end
