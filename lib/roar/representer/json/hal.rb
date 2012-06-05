module Roar::Representer
  module JSON
    # Including the JSON::HAL module in your representer will render and parse documents
    # following the HAL specification: http://stateless.co/hal_specification.html
    # Links will be embedded using the +_links+ key, nested resources with the +_embedded+ key.
    #
    # Embedded resources can be specified when calling #property or +collection using the
    # :embedded => true option.
    #
    # Example:
    # 
    #   module OrderRepresenter
    #     include Roar::Representer::JSON::HAL
    #     
    #     property :id
    #     collection :items, :class => Item, :extend => ItemRepresenter, :embedded => true
    #
    #     link :self do
    #       "http://orders/#{id}"
    #     end
    #   end
    #
    # Renders to
    #
    #   "{\"id\":1,\"_embedded\":{\"items\":[{\"value\":\"Beer\",\"_links\":{\"self\":{\"href\":\"http://items/Beer\"}}}]},\"_links\":{\"self\":{\"href\":\"http://orders/1\"}}}"
    module HAL
      def self.included(base)
        base.class_eval do
          include Roar::Representer::JSON
          include Links       # overwrites #links_definition_options.
          extend ClassMethods # overwrites #links_definition_options, again.
          include Resources
        end
      end
      
      module Resources
        # Write the property to the +_embedded+ hash when it's a resource.
        def compile_fragment(bin, doc)
          return super unless bin.definition.options[:embedded]
          super(bin, doc[:_embedded] ||= {})
        end
        
        def uncompile_fragment(bin, doc)
          return super unless bin.definition.options[:embedded]
          super(bin, doc["_embedded"] || {})
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
                hash[link.rel] = link.extend(JSON::HyperlinkRepresenter).to_hash(:exclude => [:rel])
              end
            end
          end
          
          def from_hash(json, *)
            json ||= {} # since we override #from_hash we're responsible for this.
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
