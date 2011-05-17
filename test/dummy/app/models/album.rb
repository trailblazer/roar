class Album < ActiveRecord::Base
  has_many :songs
  validates_presence_of :year
  
  accepts_nested_attributes_for :songs, :allow_destroy => true
end
