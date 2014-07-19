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

    module ToHash
      def to_hash(options={})
        super(:exclude => [:links]).tap do |hash|
          hash["songs"]["links"] = hash["songs"].delete("_links")
      #      hash[:_links] = v[:links]
      #      v[:links] = v[:private_links] # FIXME: this is too much work we're doing (rendering links for every element).
        # prepare(represented)

          links = representable_attrs
            # TODO: make this in ::link, so we don't need all that stuff below. this is just prototyping for the architecture.
            # DISCUSS: do we need to inherit module here?
          links_hash = Class.new(Roar::Decorator) do
            include Representable::Hash
            self.representable_attrs.inherit!(links) # FIXME: we only want links and linked!!
            self.representation_wrap = false # FIXME: we only want links and linked!!
          end.new(represented).to_hash(:include => [:links])

          hash.merge!(links_hash)
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

      values :extend => LinkRepresenter#,
        # :instance => lambda { |fragment, *| fragment.is_a?(LinkArray) ? fragment : Roar::Representer::Feature::Hypermedia::Hyperlink.new }

      # def to_hash(options)
      #   super.tap do |hsh|  # TODO: cool: super(:exclude => [:rel]).
      #     hsh.each { |k,v| v.delete(:rel) }
      #   end
      # end


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
