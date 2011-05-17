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
    @album = Album.create(representation)
    
    respond_with @album
  end
  
  def update
    @album = Album.find(params[:id])
    @album.songs.delete_all # make PUT behave REST-compliant.
    @album.update_attributes(representation)
    
    respond_with @album
  end
end
