require 'roar/json'
require 'roar/decorator'

module Roar
  module JSON
    module JSONAPI
      def self.included(base)
        base.class_eval do
          include Roar::JSON
          include Roar::Hypermedia
          extend JSONAPI::Declarative
          extend JSONAPI::ForCollection
          include JSONAPI::Document

          nested :relationships do
          end

          nested :included do
          end
        end
      end

      module ForCollection
        def collection_representer # FIXME: cache.
          single = self # e.g. Song::Representer

          # this basically does Module.new { include Hash::Collection .. }
          nested_builder.(_base: default_nested_class, _features: [Roar::JSON, Roar::Hypermedia], _block: Proc.new do
            collection :to_a, decorator: single # render/parse every item using the single representer.

            # toplevel links are defined here, as in
            # link(:self) { .. }

            def to_hash(*)
              hash = super # [{data: {..}, data: {..}}]
              collection = hash["to_a"]

              document = {data: []}
              included = []
              collection.each do |single|
                document[:data] << single[:data]
                # included += single[:data].delete(:included)
                included += single[:data].delete(:included)||[]
              end

              document[:links] = Renderer::Links.new.(hash, {})
              document[:included] = included if included.any?
              document
            end
          end)
        end

        def for_collection # FIXME: same API as representable. TODO: we could use ::collection_representer! here.
          @collection_representer ||= collection_representer
        end
      end

      # New API for JSON-API representers.
      module Declarative
        def type(name=nil)
          return super unless name # original name.
          representable_attrs[:_wrap] = name.to_s
        end

        def link(name, options={}, &block)
          return super(name, &block) unless options[:toplevel]
          for_collection.link(name, &block)
        end

        def meta(&block)
          representable_attrs[:meta_representer] = Class.new(Roar::Decorator, &block)
        end

        def has_one(name, options={}, &block)
          # every nested representer is a full-blown JSONAPI representer.
          nested(:relationships, inherit: true) do
            property(name, options) do
              include Roar::JSON::JSONAPI
              include Roar::JSON
              include Roar::Hypermedia

              instance_exec(&block)

              def from_document(hash)
                hash
              end
            end
          end

          bla = representable_attrs.get(:relationships)
          nested(:included, inherit: true) do # FIXME: make that a bit nicer readable and document what i'm doing here.
            property(name, decorator: bla[:extend].(nil).representable_attrs.get(name)[:extend].(nil), collection: options[:collection])
          end
        end

        def has_many(name, options={}, &block)
          has_one(name, options.merge(collection: true), &block)
        end
      end

      module Renderer
        class Links
          def call(res, options)
            tuples = (res.delete("links") || []).collect { |link| [link["rel"], link["href"]] }
            # tuples.to_h
            ::Hash[tuples] # TODO: tuples.to_h when dropping < 2.1.
          end
        end
      end

      module Document
        def to_hash(options={})
          res = super
          links = Renderer::Links.new.call(res, options)
          # meta  = render_meta(options)

          relationships = render_relationships(res)
          included      = render_included(res)

          document = {
            data: data = {
              type: representable_attrs[:_wrap],
              id: res.delete("id").to_s
            }
          }
          data[:attributes]    = res unless res.empty?
          data[:relationships] = relationships if relationships and relationships.any?
          data[:links]         = links unless links.empty?
          data[:included]      = included if included and included.any?

          document
        end

        def from_hash(hash, options={})
          super(from_document(hash))
        end

      private
        def from_document(hash)
          # hash[representable_attrs[:_wrap]]
          raise Exception.new('Unknown Type') unless hash['data']['type'] == representable_attrs[:_wrap]

          # hash: {"data"=>{"type"=>"articles", "attributes"=>{"title"=>"Ember Hamster"}, "relationships"=>{"author"=>{"data"=>{"type"=>"people", "id"=>"9"}}}}}
          attributes = hash["data"]["attributes"] || {}
          attributes["relationships"] = {}

          hash["data"]["relationships"].each do |rel, fragment| # FIXME: what if nil?
            attributes["relationships"][rel] = fragment["data"] # DISCUSS: we could use a relationship representer here (but only if needed elsewhere).
          end

          # this is the format the object representer understands.
          attributes # {"title"=>"Ember Hamster", "author"=>{"type"=>"people", "id"=>"9"}}
        end

        # Go through {"album"=>{"title"=>"Hackers"}, "musicians"=>[{"name"=>"Eddie Van Halen"}, ..]} from linked:
        # and wrap every item in an array.
        def render_included(hash)
          return unless compound = hash.delete("included")

          compound.collect do |name, hash|
            if hash.is_a?(::Hash)
              hash[:data]
            else
              hash.collect { |item| item[:data] }
            end
          end.flatten
        end

        def render_meta(options)
          # TODO: this will call collection.page etc, directly on the collection. we could allow using a "meta"
          # object to hold this data.
          # `meta call_meta: true` or something
          return {"meta" => options["meta"]} if options["meta"]
          return {} unless representer = representable_attrs[:meta_representer]
          {"meta" => representer.new(represented).extend(Representable::Hash).to_hash}
        end

        def render_relationships(res)
          (res["relationships"] || []).each do |name, hash|
            if hash.is_a?(::Hash)
              hash[:links] = hash[:data].delete(:links)
            else # hash => [{data: {}}, ..]
              res["relationships"][name] = collection = {data: []}
              hash.each do |hsh|
                collection[:links] = hsh[:data].delete(:links) # FIXME: this is horrible.
                collection[:data] << hsh[:data]
              end
            end
          end
          res.delete("relationships")
        end
      end
    end
  end
end
