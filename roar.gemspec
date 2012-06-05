# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "roar/version"

Gem::Specification.new do |s|
  s.name        = "roar"
  s.version     = Roar::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nick Sutterer"]
  s.email       = ["apotonick@gmail.com"]
  s.homepage    = "http://rubygems.org/gems/roar"
  s.summary     = %q{Resource-oriented architectures in Ruby.}
  s.description = %q{Streamlines the development of RESTful, resource-oriented architectures in Ruby.}

  s.rubyforge_project = "roar"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_runtime_dependency "representable", ">= 1.2.2"
  
  s.add_development_dependency "rake"
  s.add_development_dependency "test_xml"
  s.add_development_dependency "minitest",	">= 2.8.1"
end
