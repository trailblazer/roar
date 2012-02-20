require "roar/representer/feature/http_verbs"

module Roar
  # Automatically add accessors for properties and collections. Also mixes in HttpVerbs.
  module Representer
    module Feature
      module Client
        include HttpVerbs
        
        def self.extended(base)
          base.instance_eval do
            representable_attrs.each do |attr|
              next unless attr.instance_of? Representable::Definition # ignore hyperlinks etc for now.
              name = attr.name
              
              # TODO: could anyone please make this better?
              instance_eval %Q{
                def #{name}=(v)
                  @#{name} = v
                end
                
                def #{name}
                  @#{name}
                end
              }
            end
          end
        end
      end
    end
  end
end
