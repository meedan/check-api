class Source < ActiveRecord::Base
  attr_accessible

  has_many :accounts
  has_many :project_sources
  has_many :projects , :through => :project_sources
  mount_uploader :avatar, ImageUploader

end
