class Bot < ActiveRecord::Base

  mount_uploader :avatar, ImageUploader
  validates_presence_of :name

end
