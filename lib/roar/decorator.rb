class Roar::Decorator < Representable::Decorator
  extend Roar::Representer::InheritableArray

  module HypermediaConsumer
    def links_array=(*args)
      super # TODO: this currently sets #links which is not obvious.
      represented.links = links
    end
  end
end