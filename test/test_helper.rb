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


class MiniTest::Spec
  def assert_model(expected, subject)
    assert_instance_of subject.class, expected 
    
    expected.attributes.each_pair do |k, v|
      if v.is_a?(Array)
        v.each do |item|
          subject_collection = subject.attributes[k]
          assert_equal(item.attributes, subject_collection, "in #{expected.class}.#{k}") if subject_collection.blank?
          assert_model item, subject_collection[v.index(item)]
        end
        
      else
        assert_equal v.to_s, subject.attributes[k].to_s, "#{v.inspect} is not #{subject.attributes[k].inspect} in #{expected.class}.#{k}"
      end
    end
    
    
  end
end
