require 'rubygems'
require 'sinatra/base'
require 'active_support'
require 'json'

class FakeServer < Sinatra::Base
  put "/test/put" do
    request.body
  end

  get "/test/get" do
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n  <test-object>\n<id>9</id>\n  </test-object>\n"
  end

  get "/test/:id" do
    "<test><id>#{params[:id]}</id></test>"
  end

  


  get "/eine-ressource-in-xml" do
    "<name>eine-ressource</name>"
  end
end

FakeServer.run! :host => 'localhost', :port => 9999
