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
        
        def from(mime_type, representation)
          representer_class_for(mime_type).deserialize(self, mime_type, representation)
        end
      end
      
      def to(mime_type)
        self.class.representer_class_for(mime_type).new.serialize(self, mime_type)
      end
    end
  end
end
