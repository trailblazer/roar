require "bundler/setup"
require 'sinatra/base'

class FakeServer < Sinatra::Base
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
  
  #patch "/method" do
  #  "<method>patch</method>"
  #end
  
  post "/bands" do
    #if request.content_type =~ /xml/
      '{"label": "n/a", "name": "Strung Out", "links": [{"href":"http://search", "rel": "search"}, {"href":"http://band/strungout", "rel": "self"}]}'
  end
  
  put "/bands/strungout" do
    {:name => "Strung Out", :label => "Fat Wreck"}.to_json
  end
  
  get "/bands/slayer" do
    {:name => "Slayer", :label => "Canadian Maple"}.to_json
  end
  
  
  require './test/order_representers'
  JSON::Order.class_eval do
    def items_url
      "http://roar.example.com/orders/1/items"
    end
    def order_url(order)
      "http://roar.example.com/orders/#{order}"
    end
    def represented
      1
    end
    
  end
  
  
  post "/orders" do
    incoming = JSON::Order.deserialize(request.body.string)
    # create new record
    
    # render new record
    
    JSON::Order.from_attributes(incoming.to_attributes).serialize
  end
  
  post "/orders/1/items" do
    incoming = JSON::Item.deserialize(request.body.string)
    
    JSON::Item.from_attributes(incoming.to_attributes).serialize
  end
  
  get "/orders/1" do
    JSON::Order.new(:client_id => 1, :items => [JSON::Item.new(:article_id => "666-S", :amount => 1)]).serialize
  end
  
end

