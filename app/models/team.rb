class Team < ActiveRecord::Base
  attr_accessible

  has_many :teamUsers
  has_many :users, :through => :teamUsers
  mount_uploader :logo, ImageUploader

end
