require 'roar/representer/json'
require 'roar/decorator'

module Roar
  module JSON
    module JsonApi
      def self.included(base)
        base.class_eval do
          include Representable::Hash
          include Roar::JSON::JsonApi::Singular
          include Roar::JSON::JsonApi::Resource
          include Roar::JSON::JsonApi::Document

          extend ForCollection
        end
      end

      module ForCollection
        def for_collection # same API as representable. TODO: we could use ::collection_representer! here.
          singular = self # e.g. Song::Representer

          # this basically does Module.new { include Hash::Collection .. }
          build_inline(nil, [Document::Collection, Representable::Hash::Collection], "", {}) do
            items extend: singular, :parse_strategy => :sync

            representable_attrs[:resource_representer] = singular.send :resource_representer
            representable_attrs[:_wrap] = singular.representable_attrs[:_wrap]
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

        def from_hash(hash, options={})
          hash["_links"] = hash["links"]
          super
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

        # New API for JSON-API representers.
        module Declarative
          def name(name=nil)
            return super unless name # original name.
            representable_attrs[:_wrap] = name.to_s
          end

          # Define global document links in the links: directive.
          def link(*args, &block)
            resource_representer.link(*args, &block)
          end

          # Per-model links.
          def links(&block)
            nested(:_links, &block)
          end

          # TODO: always create _links.
          def has_one(name)
            property :_links, :inherit => true, :use_decorator => true do # simply extend the Decorator _links.
              property "#{name}_id", :as => name
            end
          end

          def has_many(name)
            property :_links, :inherit => true, :use_decorator => true do # simply extend the Decorator _links.
              collection "#{name.to_s.sub(/s$/, "")}_ids", :as => name
            end
          end

          def compound(&block)
            nested(:linked, &block)
          end

        private
          def resource_representer
            representable_attrs[:resource_representer] ||= Representer # TODO: make sure gets cloned!
          end
        end
      end


      # TODO: don't use Document for singular+wrap AND singular in collection (this way, we can get rid of the only_body)
      module Document
        def to_hash(options={})
          # per resource:
          res = super # render single resource or collection.
          return res if options[:only_body]
          # this is the only "dirty" part: this module is always included in the Singular document representer, when used in collection, we don't want it to do the extra work. this mechanism here might be changed soon.

          to_document(res)
        end

        def from_hash(hash, options={})

          return super(hash, options) if options[:only_body] # singular

          super(from_document(hash)) # singular
        end

      private
        def to_document(res)
          links    = representable_attrs[:resource_representer].new(represented).to_hash
          compound = res.delete("linked")

          {representable_attrs[:_wrap] => res}.merge( links).merge("linked" => compound)
        end

        def from_document(hash)
          hash[representable_attrs[:_wrap]]
        end


        module Collection
          include Document

          def to_hash(options={})
            res = super(options.merge(:only_body => true))
            to_document(res)
          end

          def from_hash(hash, options={})
            hash = from_document(hash)
            super(hash, options.merge(:only_body => true))
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
