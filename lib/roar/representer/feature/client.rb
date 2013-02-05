require "roar/representer/feature/http_verbs"

module Roar
  # Automatically add accessors for properties and collections. Also mixes in HttpVerbs.
  module Representer
    module Feature
      module Client
        include HttpVerbs

        def self.extended(base)
          target = base.is_a?(Module) ? base : base.singleton_class

          target.class_eval do
            base.send(:representable_attrs).each do |attr|
              next unless attr.instance_of? Representable::Definition # ignore hyperlinks etc for now.
              attr_accessor attr.name
            end
          end
        end
      end
    end
  end
end
