module Roar
  # Define hypermedia links in your representations.
  #
  # Example:
  #
  #   class Order
  #     include Roar:JSON
  #
  #     property :id
  #
  #     link :self do
  #       "http://orders/#{id}"
  #     end
  #
  # If you want more attributes, just pass a hash to #link.
  #
  #     link :rel => :next, :title => "Next, please!" do
  #       "http://orders/#{id}"
  #     end
  #
  # If you need dynamic attributes, the block can return a hash.
  #
  #     link :preview do
  #       {:href => image.url, :title => image.name}
  #     end
  #
  # Sometimes you need values from outside when the representation links are rendered. Just pass them
  # to the render method, they will be available as block parameters.
  #
  #   link :self do |opts|
  #     "http://orders/#{opts[:id]}"
  #   end
  #
  #   model.to_json(:id => 1)
  module Hypermedia
    # links= [Hyperlink, Hyperlink] is where parsing happens.
    def self.included(base)
      base.extend ClassMethods
    end

    # public API: #links (only helpful in clients, though).
    attr_writer :links # this is called in parsing when Hyperlinks are deserialized.
    def links # this is _not_ called by rendering as we go via ::links_config.
      hash = {}
      @links.collect { |link| [link.rel, link] }.to_h
    end


    module LinkConfigsMethod
      def link_configs # we could store the ::link configs in links Definition.
        representable_attrs[:links] ||= Representable::Inheritable::Array.new
      end
    end

    include LinkConfigsMethod

  private
    # Create hypermedia links for this instance by invoking their blocks.
    # This is called in links: getter: {}.
    def prepare_links!(options)
      return [] if options[:links] == false

      compile_links_for(link_configs, options)
    end

    def compile_links_for(configs, *args)
      configs.collect do |config|
        options, block  = config.first, config.last
        href            = run_link_block(block, *args) or next

        prepare_link_for(href, options)
      end.compact # FIXME: make this less ugly.
    end

    def prepare_link_for(href, options)
      options = options.merge(href.is_a?(::Hash) ? href : {href: href})
      Hyperlink.new(options)
    end

    def run_link_block(block, *args)
      instance_exec(*args, &block)
    end


    module ClassMethods
      # Declares a hypermedia link in the document.
      #
      # Example:
      #
      #   link :self do
      #     "http://orders/#{id}"
      #   end
      #
      # The block is executed in instance context, so you may call properties or other accessors.
      # Note that you're free to put decider logic into #link blocks, too.
      def link(options, &block)
        create_links_definition! # this assures the links are rendered at the right position.

        options = {:rel => options} unless options.is_a?(::Hash)
        link_configs << [options, block]
      end

      include LinkConfigsMethod

    private
      # Add a :links Definition to the representable_attrs so they get rendered/parsed.
      def create_links_definition!
        return if representable_attrs.get(:links) # only create it once.

        options = links_definition_options
        options.merge!(getter: ->(options) { prepare_links!(options) })

        property(:links, options) # this defines something along `collection :links, getter: ->(prepare)`.
      end
    end


    # An abstract hypermedia link with arbitrary attributes.
    class Hyperlink
      extend Forwardable
      def_delegators :@attrs, :each, :collect

       def initialize(attrs={})
         @attrs = attributes!(attrs)
       end

      def replace(attrs) # makes it work with Hash::Hash.
        @attrs = attributes!(attrs)
        self
      end

      # Only way to write to Hyperlink after creation.
      def merge!(attrs)
        @attrs.merge!(attributes!(attrs))
      end

    private
      def method_missing(name)
        @attrs[name.to_s]
      end

      # Converts keys to strings.
      def attributes!(attrs)
        attrs.inject({}) { |hsh, kv| hsh[kv.first.to_s] = kv.last; hsh }.tap do |hsh|
          hsh["rel"] = hsh["rel"].to_s if hsh["rel"]
        end
      end
    end
  end
end
