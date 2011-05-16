class Album < ActiveRecord::Base
  has_many :songs
end
