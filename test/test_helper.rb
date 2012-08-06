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

class Product
  include AttributesConstructor
  attr_accessor :id, :name, :title
end

class Order
  include AttributesConstructor
  attr_accessor :id, :items, :total, :currency, :status, :upsells
end

class Factory
  include AttributesConstructor
  attr_accessor :orders, :currentlyProcessing, :shippedToday
end

require "test_xml/mini_test"
require "roar/representer/xml"

require 'sham_rack'
require './test/fake_server'

ShamRack.at('roar.example.com').rackup do
  run FakeServer
end
