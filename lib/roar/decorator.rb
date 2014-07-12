require 'roar/representer'
require 'representable/decorator'

class Roar::Decorator < Representable::Decorator
  module HypermediaConsumer
    def links=(args)
      puts "-------------------> #{args.inspect}"
      super
      represented.links = args
    end
  end
end