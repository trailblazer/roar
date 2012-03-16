module Roar::Representer
  module JSON
    module HAL
      def self.included(base)
        base.class_eval do
          include Roar::Representer::JSON
          include Links       # overwrites #links_definition_options.
          extend ClassMethods # overwrites #links_definition_options, again.
        end
      end
      
      
      module ClassMethods
        def links_definition_options
          super.tap { |options| options[1].merge!({:from => :_links}) }
        end
      end
      
      # Including this module in your representer will render and parse your embedded hyperlinks
      # following the HAL specification: http://stateless.co/hal_specification.html
      #
      #   module SongRepresenter
      #     include Roar::Representer::JSON
      #     include Roar::Representer::JSON::HAL::Links
      #     
      #     link :self { "http://self" }
      #   end
      #
      # Renders to
      #
      #   {"links":{"self":{"href":"http://self"}}}
      #
      # Note that the HAL::Links module alone doesn't prepend an underscore to +links+. Use the JSON::HAL module for that.
      module Links
        # TODO: allow more attributes besides :href in Hyperlink.
        def self.included(base)
          base.class_eval do
            include Roar::Representer::Feature::Hypermedia
            extend Links::ClassMethods
          end
        end
        
        
        module LinkCollectionRepresenter
          include JSON
          
          def to_hash(*)
            {}.tap do |hash|
              each do |link|
                # TODO: we statically use JSON::HyperlinkRepresenter here.
                hash[link.rel] = link.extend(JSON::HyperlinkRepresenter).to_hash(:except => [:rel])
              end
            end
          end
          
          def from_hash(json, *)
            json.each do |k, v|
              self << Feature::Hypermedia::Hyperlink.new(v.merge :rel => k)
            end
            self
          end
        end
        
        
        module ClassMethods
          def links_definition_options
            super.tap { |options| options[1] = {:class => Feature::Hypermedia::LinkCollection, :extend => LinkCollectionRepresenter} }
          end
        end
      end
    end
  end
end
