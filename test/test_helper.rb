require 'bundler'
Bundler.setup

require 'test/unit'
require 'minitest/spec'

require 'roar/representer'
require 'roar/representer/feature/http_verbs'


module AttributesContructor
  def initialize(attrs={})
    attrs.each do |k,v|
      instance_variable_set("@#{k}", v)
    end
  end
end

class Item
  include AttributesContructor
  attr_accessor :value
end

class Position
  include AttributesContructor
  attr_accessor :id, :item
end

class Order
  include AttributesContructor
  attr_accessor :id, :items
end

require "test_xml/mini_test"
require "roar/representer/xml"
