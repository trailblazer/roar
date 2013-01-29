module Roar::Representer::JSON
  # Implementation of the Collection+JSON media format, http://amundsen.com/media-types/collection/format/
  module CollectionJSON
    def self.included(base)
      base.class_eval do
        include Roar::Representer
        include Roar::Representer::JSON
        include Roar::Representer::Feature::Hypermedia

        extend ClassMethods
        #include InstanceMethods # otherwise Representable overrides our #to_json.

        self.representation_wrap= :collection # FIXME: move outside of this block for inheritance!

        property :template, :extend => lambda {|*| representable_attrs.collection_representers[:template] }
        def template
          OpenStruct.new  # TODO: handle preset values.
        end

        collection :queries, :extend => lambda {|*| representable_attrs.collection_representers[:queries] }
        def queries
          compile_links_for representable_attrs.collection_representers[:queries].representable_attrs.first
        end

        collection :items, :extend => lambda {|*| representable_attrs.collection_representers[:items] }
        def items
          self
        end
      end
    end

    module ClassMethods
      module PropertyWithRenderNil
        def property(name, options={})
          super(name, options.merge!(:render_nil => true))
        end
      end

      # TODO: provide automatic copying from the ItemRepresenter here.
      def template(&block)
        mod = representable_attrs.collection_representers[:template] = Module.new do
          include Roar::Representer::JSON
          include Roar::Representer::JSON::CollectionJSON::DataMethods
          
          extend PropertyWithRenderNil

          module_exec(&block)
        end
      end

      def queries(&block)
        mod = representable_attrs.collection_representers[:queries] = Module.new do
          include Roar::Representer::JSON
          include Roar::Representer::Feature::Hypermedia
          
          module_exec(&block)
        end
      end

      def items(&block)
        mod = representable_attrs.collection_representers[:items] = Module.new do
          include Roar::Representer::JSON
          include Roar::Representer::Feature::Hypermedia
          include Roar::Representer::JSON::CollectionJSON::DataMethods

          module_exec(&block)
        end
      end

      def representable_attrs
        super.tap do |attrs|
          attrs.instance_eval do # FIXME: of course, this is WIP.
            def collection_representers
              @collection_representers ||= {}
            end
          end
        end
      end
    end

    module DataMethods
      def to_hash(*)
        hash = super.tap do |hsh|
          data = []
          hsh.keys.each do |n|
            next if ["href", "links"].include?(n)

            v = hsh.delete(n.to_s)
            data << {:name => n, :value => v} # TODO: get :prompt from Definition.
          end
          hsh[:data] = data
        end
      end
    end
  end
end