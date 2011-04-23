require 'bundler'
Bundler.setup

require 'test/unit'
require 'minitest/spec'

require 'active_model'
require 'roar/client/entity_proxy'
require 'roar/client/proxy'
require 'roar/representer'
require 'roar/representer/xml'
require 'roar/model'
require 'roar/model/http_verbs'

require 'stringio'  # FIXME. remove for 3.0.4.
require 'builder'

# TODO: move to fixtures.rb
class TestModel
  include Roar::Representer::Xml
  include Roar::Model  # gives us #attributes.
  
  def self.model_name
    "test"
  end
  
  accessors :item, :id
  
  def ==(b)
    attributes == b.attributes
  end
end

class Item
  include Roar::Model
  accessors :value
  
  def self.model_name
    "item"
  end
end

class Position
  include Roar::Model
  accessors :id, :item
  
  def self.model_name
    :order
  end
end

class Order
  include Roar::Model
  accessors :id, :items
  
  def self.model_name
    :order
  end
end

require "test_xml/mini_test"
require "roxml"
require "roar/representer/roxml"
