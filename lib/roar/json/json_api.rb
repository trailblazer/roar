require 'roar/json'
require 'roar/decorator'

module Roar
  module JSON
    module JSONAPI
      def self.included(base)
        base.class_eval do
          include Representable::JSON
          include Roar::JSON::JSONAPI::Resource
          include Roar::JSON::JSONAPI::Document

          extend ForCollection

          # representable_attrs[:resource_representer] = Class.new(Resource::Representer)

          private
            def create_representation_with(doc, options, format)
              super(doc, options.merge(:only_body => true), format)
            end
        end
      end

      module ForCollection
        def for_collection # same API as representable. TODO: we could use ::collection_representer! here.
          singular = self # e.g. Song::Representer

          # this basically does Module.new { include Hash::Collection .. }
          build_inline(nil, [Representable::Hash::Collection, Document::Collection, Roar::JSON, Roar::JSON::JSONAPI, Roar::Hypermedia], "", {}) do
            items extend: singular, :parse_strategy => :sync

            representable_attrs[:resource_representer] = singular.representable_attrs[:resource_representer]
            representable_attrs[:meta_representer]     = singular.representable_attrs[:meta_representer] # DISCUSS: do we need that?
            representable_attrs[:_wrap] = singular.representable_attrs[:_wrap]
            representable_attrs[:_href] = singular.representable_attrs[:_href]
          end
        end
      end

      module Resource
        def self.included(base)
          base.extend Declarative # inject our ::link.
        end

        # New API for JSON-API representers.
        module Declarative
          def type(name=nil)
            return super unless name # original name.
            representable_attrs[:_wrap] = name.to_s
          end

          def href(name=nil)
            representable_attrs[:_href] = name.to_s
          end

          # Per-model links.
          def links(&block)
            nested(:_links, :inherit => true, &block)
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
            nested(:included, &block)
          end

          def meta(&block)
            representable_attrs[:meta_representer] = Class.new(Roar::Decorator, &block)
          end
        end
      end


      # TODO: don't use Document for singular+wrap AND singular in collection (this way, we can get rid of the only_body)
      module Document
        def to_hash(options={})
          res = super # render single resource or collection.
          to_document(res, options)
        end

        def from_hash(hash, options={})
          super(from_document(hash))
        end

      private
        def to_document(res, options)
          links = render_links(res, options)
          # meta  = render_meta(options)

          relationships = render_relationships(res)
          included      = render_included(res)

          # if res.is_a?(Array)
          #   compound = collection_compound!(res, {})
          # else
            # compound = compile_compound!(res.delete("included"), {})
          # end

          document = {
            data: data = {
              type: representable_attrs[:_wrap],
              id: res.delete('id').to_s
            }
          }
          data[:attributes]    = res unless res.empty?
          data[:relationships] = relationships if relationships and relationships.any?
          data[:links]         = links unless links.empty?
          data[:included]      = included if included and included.any?

          # doc.merge!(meta)
          document
        end

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
            if hash.is_a?(Hash)
              hash[:data]
            else
              hash.collect { |item| item[:data] }
            end
          end.flatten
        end

        def render_links(res, options)
          (res.delete("links") || []).collect { |link| [link["rel"], link["href"]] }.to_h
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
            if hash.is_a?(Hash)
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
