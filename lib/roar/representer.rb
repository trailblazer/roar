require 'representable'

module Roar
  module Representer
    # TODO: move to separate module
    # DISCUSS: experimental. this will soon be moved to a separate gem
    module InheritableArray
      def representable_attrs
        super.extend(ConfigExtensions)
      end

      module ConfigExtensions
        def inheritable_array(name)
          inheritable_arrays[name] ||= []
        end
        def inheritable_arrays
          @inheritable_arrays ||= {}
        end

        def inherit(parent)
          super
          
          parent.inheritable_arrays.keys.each do |k|
            inheritable_array(k).push *parent.inheritable_array(k).clone
          end
        end
      end
    end

    def self.included(base)
      base.class_eval do
        include Representable
      end
    end

    include InheritableArray

  private
    def before_serialize(*)
    end
  end
end
