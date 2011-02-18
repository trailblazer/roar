module Roar
  module Model
    module Representable
      extend ActiveSupport::Concern
      
      included do |base|
        base.extend Hooks::InheritableAttribute
        base.inheritable_attr :representable
        base.representable = {} # FIXME: doesn't that break inheritance?
      end
      
      module ClassMethods
        def represents(mime_type, options)
          self.representable[mime_type] = options[:with]
        end
        
        def representer_class_for(mime_type)
          representable[mime_type]
        end
        
      end
    end
  end
end
