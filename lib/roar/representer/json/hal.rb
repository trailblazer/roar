module Roar::Representer
  module JSON
    module HAL
      def self.included(base)
        base.class_eval do
          include Roar::Representer::JSON
          include Roar::Representer::Feature::Hypermedia
          extend ClassMethods
        end
      end
      
      
      module LinkCollectionRepresenter
        include JSON
        
        def to_hash(*)
          {}.tap do |hash|
            each do |link|
              hash[link.rel] = link.href
            end
          end
        end
        
        def from_hash(json, *)
          json.each do |k, v|
            self << Feature::Hypermedia::Hyperlink.new(:rel => k, :href => v)
          end
          self
        end
      end
      
      
      module ClassMethods
        def links_definition_options
          options = super
          options[1] = {:class => Feature::Hypermedia::LinkCollection, :from => :_links, :extend => LinkCollectionRepresenter}
          options
        end
      end
    end
  end
end
