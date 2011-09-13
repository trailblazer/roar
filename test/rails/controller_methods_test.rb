require 'test_helper'
require 'roar/rails/test_case'
require "dummy/config/environment"
require "rails/test_help" # adds stuff like @routes, etc.

module Representer
  module BMP
    class Album; end
  end
end
    
class ControllerMethodsTest < ActionController::TestCase
  tests AlbumsController
  
  test "responds to #responder" do
    assert_equal Roar::Rails::ControllerMethods::Responder, @controller.class.responder
  end
  
  test "responds to #represents" do
    @controller = Class.new(AlbumsController)
    assert_equal Album, @controller.represented_class
    @controller.represents Song
    assert_equal Song, @controller.represented_class
  end
  
  test "responds to #representer_class_for" do
    assert_equal Representer::BMP::Album, @controller.representer_class_for(Album, :bmp)
  end
  
  test "responds to #representation" do
    post :create, %{<album>
      <year>2011</year>
      <song>
        <title>Walking In Your Footsteps</title>
      </song>
    </album>}, :format => :xml
    
     
    assert_equal({"id"=>"", "year"=>"2011",
      "songs_attributes"=>[{"title"=>"Walking In Your Footsteps"}]}, @controller.representation)
  end
  
  test "responds to #incoming" do
    post :create, %{<album>
      <year>2011</year>
      <song>
        <title>Walking In Your Footsteps</title>
      </song>
    </album>}, :format => :xml
    
     
    assert_equal({"id"=>"", "year"=>"2011",
      "songs"=>[{"title"=>"Walking In Your Footsteps"}], "links"=>[]}, @controller.incoming.to_attributes)
  end
end


class ControllerFunctionalTest < ActionController::TestCase
  tests AlbumsController
  
  test "GET: returns a xml representation" do
    get :show, :id => 1, :format => :xml
    
    assert_response 200
    assert_body %{
    <album>
      <id>1</id>  
      <year>2011</year>
      <song>
        <title>Alltax</title>
      </song>
      <song>
        <title>Bali</title>
      </song>
      
      <link rel="self"      href="http://test.host/albums/1" />
      <link rel="album-search"  href="http://test.host/articles/starts_with/{query}" />
    </album>}, :format => :xml
  end
  
  test "POST: creates a new album and returns the xml representation" do
    post :create, %{<album>
      <year>1997</year>
      <song>
        <title>Cooler Than You</title>
      </song>
    </album>}, :format => :xml
    
    assert @album = Album.find(:last)
    assert_equal "1997", @album.year
    assert_equal "Cooler Than You", @album.songs.first.title
    
    assert_response 201, "Location" => album_url(@album) # Created
    assert_body %{
    <album>
      <id>2</id>  
      <year>1997</year>
      <song>
        <title>Cooler Than You</title>
      </song>
      
      <link rel="self"      href="http://test.host/albums/2" />
      <link rel="album-search"  href="http://test.host/articles/starts_with/{query}" />
    </album>}, :format => :xml
  end
  
  test "POST: invalid incoming representations yields to 422" do
    post :create, :format => :xml
    
    assert_response 422  # Unprocessable Entity
  end
  
  test "PUT: updates album and returns the xml representation" do
    put :update, %{
    <album>
      <year>1997</year>
      <song>
        <title>Cooler Than You</title>
      </song>
      <song>
        <title>Rubbing The Elf</title>
      </song>
    </album>}, :id => 1, :format => :xml
    
    assert @album = Album.find(1)
    assert_equal "1997", @album.year
    assert_equal 2, @album.songs.size
    assert_equal "Cooler Than You", @album.songs.first.title
    assert_equal "Rubbing The Elf", @album.songs.last.title
    
    assert_response 200
    assert_body %{
    <album>
      <id>1</id>
      <year>1997</year>
      <song>
        <title>Cooler Than You</title>
      </song>
      <song>
        <title>Rubbing The Elf</title>
      </song>
      
      <link rel="self"      href="http://test.host/albums/1" />
      <link rel="album-search"  href="http://test.host/articles/starts_with/{query}" />
    </album>}, :format => :xml
  end
end
