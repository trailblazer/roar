module Roar
  # deserialize
  # serialize
  module Representer
    class Base
    end
    
    require "roxml/definition"
    class LinksDefinition < ROXML::Definition
      def rel2block
        @rel2block ||= []
      end
      
      def populate(representer, *args)
        representer.links ||= []
        
        rel2block.each do |link|
          representer.links << sought_type.from_attributes({  # create Hyperlink representer.
            "rel"   => link[:rel],
            "href"  => representer.instance_exec(&link[:block])})  # DISCUSS: run block in representer context?
        end
      end
    end
    
  end
end
