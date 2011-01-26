require 'bundler'
Bundler.setup

require 'test/unit'
require 'minitest/spec'

require 'active_model'
require 'roar/client/proxy'
require 'roar/representer/xml'

require 'stringio'  # FIXME. remove for 3.0.4.
require 'builder'

# TODO: move to fixtures.rb
class TestModel
  include Roar::Representer::Xml
  
  attr_accessor :attributes
  
  def self.model_name
    "test"
  end
  
  def initialize(attributes={})
    @attributes = attributes
  end
end
