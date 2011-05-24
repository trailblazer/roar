require 'rubygems'
require 'sinatra/base'
require 'active_support'
require 'json'

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
end

FakeServer.run! :host => 'localhost', :port => 9999
