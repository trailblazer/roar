require 'test_helper'
require 'roar/rails/test_case'
require "dummy/config/environment"
require "rails/test_help" # adds stuff like @routes, etc.

module Representer
  module CSV
    class AlbumRepresenter; end
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
  
  test "reponds to #representer_class_for" do
    assert_equal Representer::CSV::AlbumRepresenter, @controller.representer_class_for(Album, :csv)
  end
  
  # TODO: all functional tests from order-service here.
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
end
