require 'bundler'
Bundler.setup

require 'test/unit'
require 'minitest/spec'

require 'roar/representer'
require 'roar/representer/feature/http_verbs'

begin
  require 'turn'

  Turn.config do |config|
    config.format  = :dotted
    # config.trace   = true
  end
rescue LoadError
end

module AttributesConstructor
  def initialize(attrs={})
    attrs.each do |k,v|
      instance_variable_set("@#{k}", v)
    end
  end
end

class Item
  include AttributesConstructor
  attr_accessor :value
end

class Position
  include AttributesConstructor
  attr_accessor :id, :item
end

class Order
  include AttributesConstructor
  attr_accessor :id, :items
end

require "test_xml/mini_test"
require "roar/representer/xml"

require 'sham_rack'
require './test/fake_server'

ShamRack.at('roar.example.com').rackup do
  run FakeServer
end

MiniTest::Spec.class_eval do
  def link(options)
    Roar::Representer::Feature::Hypermedia::Hyperlink.new(options)
  end

  def self.representer_for(&block) # FIXME: move to test_helper.
    let (:rpr) do
      Module.new do
        include Roar::Representer::JSON
        include Roar::Representer::Feature::Hypermedia

        instance_exec(&block)
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