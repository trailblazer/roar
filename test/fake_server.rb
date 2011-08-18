require "bundler/setup"
require 'sinatra/base'
require 'sinatra/reloader'


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
  
  post "/band" do
    if request.content_type =~ /xml/
      %{<band><label>n/a</label><name>Strung Out</name>
        <link href="http://search" rel="search" />
        <link href="http://band/strungout" rel="self" />
      </band>}
    else
      '{"band": {"label": "n/a", "name": "Strung Out", "links": [{"href":"http://search", "rel": "search"}, {"href":"http://band/strungout", "rel": "self"}]}}'
    end
  end
  
  put "/band/strungout" do
    %{<band><label>Fat Wreck</label><name>Strung Out</name></band>}
  end
  
  
  
  require File.expand_path(File.dirname(__FILE__) + '/order_representers')
  JSON::Order.class_eval do
    def items_url
      "http://localhost:9999/orders/1/items"
    end
    def order_url(order)
      "http://localhost:9999/orders/#{order}"
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

FakeServer.run! :host => 'localhost', :port => 9999
