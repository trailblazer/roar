require 'minitest/autorun'
require 'ostruct'

require 'roar/representer'
require 'roar/representer/feature/http_verbs'
require 'roar/representer/json/hal'

module AttributesConstructor  # TODO: remove me.
  def initialize(attrs={})
    attrs.each do |k,v|
      instance_variable_set("@#{k}", v)
    end
  end
end

# FIXME: provide a real #== for OpenStruct.
class Song < OpenStruct
  def ==(other)
    name == other.name and track == other.track
  end
end

class Album < OpenStruct
end

require "test_xml/mini_test"
require "roar/representer/xml"

require "integration/runner"

MiniTest::Spec.class_eval do
  def link(options)
    Roar::Representer::Feature::Hypermedia::Hyperlink.new(options)
  end

  def self.representer_for(modules=[Roar::Representer::JSON, Roar::Representer::Feature::Hypermedia], &block)
    let (:rpr) do
      Module.new do
        include *modules.reverse

        module_exec(&block)
      end
    end
  end
end

Roar::Representer::Feature::Hypermedia::Hyperlink.class_eval do
  def ==(other)
    stringify_hash(table) == stringify_hash(other.table)
  end

  def stringify_hash(hash)
    hash.collect do |k,v|
      [k.to_s, v.to_s]
    end.sort
  end
end