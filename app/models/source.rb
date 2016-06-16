class Source < ActiveRecord::Base
  attr_accessible

  has_many :accounts
  has_many :projectSources
  has_many :projects , :through => :projectSources
  mount_uploader :avatar, ImageUploader

end
