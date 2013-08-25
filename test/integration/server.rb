require "bundler/setup"
require "sinatra"
require "ostruct"
require "roar/representer/json"

require File.expand_path("../band_representer.rb", __FILE__)

class Band
  attr_reader :name, :label

  def name=(value)
    @name = value.upcase
  end

  def label=(value)
    @label = value.upcase
  end
end

def consume_band
  Band.new.
    extend(Integration::BandRepresenter).
    from_json(request.body.read)
end

get "/method" do
  "<method>get</method>"
end

post "/method" do
  "<method>post - #{request.body.read}</method>"
end

put "/method" do
  "<method>put - #{request.body.read}</method>"
end

delete "/method" do
  "<method>delete</method>"
end

patch "/method" do
  "<method>patch - #{request.body.read}</method>"
end

get '/deliberate-error' do
  raise 'this error was deliberate'
end

post "/bands" do
  #if request.content_type =~ /xml/
  body consume_band.to_json

  status 201
end

put "/bands/strungout" do
  # DISCUSS: as long as we don't agree on what to return in PUT/PATCH, let's return an updated document.
  body consume_band.to_json
  #status 204
end

patch '/bands/strungout' do
  # DISCUSS: as long as we don't agree on what to return in PUT/PATCH, let's return an updated document.
  body consume_band.to_json
  #status 204
end

get "/bands/slayer" do
  OpenStruct.new(:name => "Slayer", :label => "Canadian Maple").
    extend(Integration::BandRepresenter).
    to_json
end

delete '/bands/metallica' do
  status 204
end
