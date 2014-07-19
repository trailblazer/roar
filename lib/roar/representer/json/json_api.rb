require 'roar/representer/json'
require 'roar/decorator'

module Roar::Representer::JSON
  module JsonApi
    def self.included(base)
      base.class_eval do
        include Roar::Representer::JSON
        include Roar::Representer::Feature::Hypermedia
        extend ClassMethods
        include ToHash
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

    module Document
      def to_hash(options={})
        # per resource:
        res = super


        # per document:
         # TODO: make this in ::link, so we don't need all that stuff below. this is just prototyping for the architecture.
            # DISCUSS: do we need to inherit module here?

        __links = representable_attrs
        # puts "inherit: #{__links.inspect}"
        links_hash = Class.new(Roar::Decorator) do
          include Representable::Hash
          # include Roar::Representer::Feature::Hypermedia
          representable_attrs.inherit!(__links) # FIXME: we only want links and linked!!
          self.representation_wrap = false # FIXME: we only want links and linked!!

          # this calls [].prepare_links! when collection.
        end.new(represented).to_hash(:include => [:links])

        hash = links_hash

        {"songs" => res}.merge(hash)
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

      def from_hash(hash, options={})
        hash.each { |k,v| hash[k] = LinkArray.new(v, k) if is_array?(k) }

        hsh = super(hash) # this is where :class and :extend do the work.

        hsh.each { |k, v| v.rel = k }
      end
    end


    module ClassMethods
      def links_definition_options
        {
          :extend   => LinkCollectionRepresenter,
          #:instance => lambda { |*| LinkCollection.new(link_array_rels) }, # defined in InstanceMethods as this is executed in represented context.
          :decorator_scope => true
        }
      end
    end
  end
end
