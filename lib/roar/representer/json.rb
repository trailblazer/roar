require 'roar/representer'
require 'roar/representer/feature/hypermedia'
require 'representable/json'

module Roar
  module Representer
    module JSON
      def self.included(base)
        base.class_eval do
          include Representer
          include Representable::JSON

          extend ClassMethods
          include InstanceMethods # otherwise Representable overrides our #to_json.
        end
      end

      module InstanceMethods
        def to_hash(*args)
          before_serialize(*args)
          super
        end

        def from_json(document, options={})
          document = '{}' if document.nil? or document.empty?

          super
        end

        # Generic entry-point for rendering.
        def serialize(*args)
          to_json(*args)
        end

        def deserialize(*args)
          from_json(*args)
        end
      end


      module ClassMethods
        def deserialize(*args)
          from_json(*args)
        end

        # TODO: move to instance method, or remove?
        def links_definition_options
          [:links, {:class => Feature::Hypermedia::Hyperlink, :extend => HyperlinkRepresenter, :collection => true}]
        end
      end


      # Represents a hyperlink in standard roar+json. 
      module HyperlinkRepresenter
        include JSON

        def update_properties_from(doc, options, format)
          self.marshal_load(doc)
          self
        end

        class << self
          alias_method :representable_extended, :extended
          def extended(base)
            representable_extended base

            base.marshal_dump.keys.each do |attributes|
              property attributes
            end
          end
        end
      end
    end
  end
end
