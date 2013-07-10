require 'roar/representer'
require 'representable/decorator'

class Roar::Decorator < Representable::Decorator
  extend Roar::Representer::InheritableArray

  module HypermediaConsumer
    def links_array=(*args)
      super # TODO: this currently sets #links which is not obvious.
      represented.links = links
    end

    # TODO: what is the deal with #links_array and #links?
    def links=(*args)
      super
      represented.links = links
    end
  end
end