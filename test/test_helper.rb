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


require "integration/band_representer"
#require '/home/nick/projects/sinatra/test/integration_helper'
class ServerRunner# < IntegrationHelper::Server
  def app_file
    File.expand_path("../integration/server.rb", __FILE__)
  end

  def run
    @pipe = IO.popen(command)
    sleep 2
  end

  def command
    "ruby #{app_file} -p 4567 -e production"
  end

  def kill
    puts "Killling : #{@pipe.pid.inspect}"
    Process.kill("KILL", @pipe.pid)
  end
end
runner = ServerRunner.new
#at_exit { puts "killing it:"; runner.kill }

runner.run

MiniTest::Unit.after_tests do
  puts "killing it"
    runner.kill
  end

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