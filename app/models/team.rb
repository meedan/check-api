class Team < ActiveRecord::Base
  attr_accessible
  has_paper_trail on: [:update]
  has_many :team_users
  has_many :users, :through => :team_users
  mount_uploader :logo, ImageUploader
  validates_presence_of :name

end
