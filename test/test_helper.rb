require 'bundler'
Bundler.setup

require 'test/unit'
require 'minitest/spec'

require 'active_model'
require 'roar/client/entity_proxy'
require 'roar/client/proxy'
require 'roar/representer'
require 'roar/representer/xml'
require 'roar/client/model_methods'
require 'roar/model/http_verbs'

require 'stringio'  # FIXME. remove for 3.0.4.
require 'builder'

# TODO: move to fixtures.rb
class TestModel
  include Roar::Representer::Xml
  include Roar::Client::ModelMethods  # gives us #attributes.
  
  def self.model_name
    "test"
  end
end

Collection = Roar::Representer::Xml::UnwrappedCollection
EntityProxy = Roar::Client::EntityProxy
