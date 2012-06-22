require "bundler/setup"
require "sinatra/base"
require "roar/representer/json"

class FakeServer < Sinatra::Base
  set :raise_errors, false

  module BandRepresenter
    include Roar::Representer::JSON
    
    property :name
    property :label
  end
  
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
    Band.new.extend(BandRepresenter).from_json(request.body.string)
  end
  
  
  get "/method" do
    "<method>get</method>"
  end

  post "/method" do
    "<method>post</method>"
  end
  
  put "/method" do
    "<method>put</method>"
  end
  
  delete "/method" do
    "<method>delete</method>"
  end
  
  patch "/method" do
    "<method>patch</method>"
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
    {:name => "Slayer", :label => "Canadian Maple"}.to_json
  end

  delete '/banks/metallica' do
    status 204
  end
end
