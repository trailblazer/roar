module Roar
  # deserialize
  # serialize
  module Representer
    class Base
      class_attribute :represented_class
      class_attribute :mime_type
      
      class << self
        def represents(klass, options) # DISCUSS: what if we don't want to hard-wire these settings into the representer?
          self.represented_class = klass
          self.mime_type = options[:as]
        end
        
      private
        def from_xml(*)
        end
      end
      
      # DISCUSS: serialize on instance?
      def serialize(represented, mime_type)
        
      end
      
      #def serialize_model(model)
      #  serialize(model.attributes)
      #end
      
      
    private
      def to_xml(*) # call #serialize instead.
      end
      
    end
    
    require "roxml/definition"
    class LinksDefinition < ROXML::Definition
      def rel2block
        @rel2block ||= []
      end
      
      def populate(representer)
        representer.links ||= []
        
        rel2block.each do |link|
          representer.links << Roar::Representer::Roxml::Hyperlink.from_attributes({"rel" => link[:rel], "href" => representer.instance_exec(&link[:block])})  # DISCUSS: run block in representer context?
        end
        
                
      end
      
    end
    
  end
end
