class Source < ActiveRecord::Base
  attr_accessible

  has_many :accounts
  has_many :project_sources
  has_many :projects , :through => :project_sources
  belongs_to :user

  mount_uploader :avatar, ImageUploader
  validates_presence_of :name

end
