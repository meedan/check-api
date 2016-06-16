class Source < ActiveRecord::Base

  has_many :accounts
  has_many :projectSources
  has_many :projects , :through => :projectSources
  mount_uploader :avatar, AvatarUploader

end
