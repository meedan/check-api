class Team < ActiveRecord::Base
  attr_accessible

  has_many :team_users
  has_many :users, :through => :team_users
  mount_uploader :logo, ImageUploader
end
