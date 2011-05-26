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
  
  post "/band" do
    %{<band><label>n/a</label><name>Strung Out</name>
      <link href="http://search" rel="search" />
      <link href="http://band/strungout" rel="self" />
    </band>}
  end
  
  put "/band/strungout" do
    %{<band><label>Fat Wreck</label><name>Strung Out</name></band>}
  end
end

FakeServer.run! :host => 'localhost', :port => 9999
