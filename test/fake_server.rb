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

  get "/article/:id" do
    "<article><id>#{params[:id]}</id></article>"
  end


  get "/eine-ressource-in-xml" do
    "<name>eine-ressource</name>"
  end
  
  get "/orders/2" do
"<order>
  <id>#{params[:id]}</id>
  <item>
    <number>1</number>
    <article>
      <uri>http://localhost:9999/article/666</uri>
    </article>
  </item>
  <item>
    <number>2</number>
    <article>
      <uri>http://localhost:9999/article/22</uri>
    </article>
  </item>
</order>
"    
  end
  
  get "/orders/:id" do
"<order>
  <id>#{params[:id]}</id>
</order>
"    
  end
  
end

FakeServer.run! :host => 'localhost', :port => 9999
