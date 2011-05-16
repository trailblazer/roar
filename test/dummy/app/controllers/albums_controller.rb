require 'roar/rails'

class AlbumsController < ActionController::Base
  include Roar::Rails::ControllerMethods
  
  respond_to :xml
  represents Album
  
  def show
    @album = Album.find(params[:id])
    respond_with @album
  end
  
  def create
    @album = Album.create(represented)
    
    respond_with @album
  end
end
