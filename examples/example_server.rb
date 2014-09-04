#!/usr/bin/env ruby

require "bundler/setup"
require "sinatra"
require "ostruct"
require "roar/representer/json"


get "/method" do
  "<method>get</method>"
end

post "/songs" do
  '{"id":"1","title":"Roxanne","links":[{"rel":"self","href":"http://localhost/songs/1"}]}'
end


get "/songs/1" do
'{"id":"1","title":"Roxanne","links":[{"rel":"self","href":"http://localhost/songs/1"}]}'
end