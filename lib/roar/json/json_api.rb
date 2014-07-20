require 'roar/representer/json'
require 'roar/decorator'

module Roar
  module JSON
    module JsonApi
      def self.included(base)
        base.class_eval do
          extend ForCollection
        end
      end

      module ForCollection
        def for_collection
          representer = self # e.g. Song::Representer

          Module.new do
            include Representable::Hash::Collection
            items extend: representer

            representable_attrs[:resource_representer] = representer.send :resource_representer

            include Roar::JSON::JsonApi::Document::Collection
          end
        end
      end


      module Singular
        def to_hash(options={})
          # per resource:
          super(:exclude => [:links]).tap do |hash|
            hash["links"] = hash.delete("_links")
          end
        end
      end


      # Include this to define your JSON-API document.
      module Resource
        # ::link is delegated to Representer which handles the hypermedia (rendering
        # and parsing links).
        class Representer < Roar::Decorator
          include Roar::Representer::JSON
          include Roar::Representer::Feature::Hypermedia

          def self.links_definition_options
            {
              :extend       => LinkCollectionRepresenter,
              :exec_context => :decorator
            }
          end
        end

        def self.included(base)
          base.extend Declarative # inject our ::link.
        end

        module Declarative
          def link(*args, &block)
            resource_representer.link(*args, &block)
          end

        private
          def resource_representer
            representable_attrs[:resource_representer] ||= Representer # TODO: make sure gets cloned!
          end
        end
      end


      module Document
        def to_hash(options={})
          # per resource:
          res = super # render single resource or collection.
          return res if options[:only_body]
          # this is the only "dirty" part: this module is always included in the Singular document representer, when used in collection, we don't want it to do the extra work. this mechanism here might be changed soon.

          to_document(res)
        end

      private
        def to_document(res)
          links_hash = representable_attrs[:resource_representer].new(represented).to_hash

          hash = links_hash

          {"songs" => res}.merge(hash)
        end


        module Collection
          include Document

          def to_hash(options={})
            res = super(options.merge(:only_body => true))
            to_document(res)
          end
        end
      end


      module LinkRepresenter
        include Roar::Representer::JSON

        property :href
        property :type
      end

      require 'representable/json/hash'
      module LinkCollectionRepresenter
        include Representable::JSON::Hash

        values :extend => LinkRepresenter # TODO: parsing.
      end
    end
  end
end
