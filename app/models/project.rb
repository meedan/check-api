class Project < ActiveRecord::Base
  attr_accessible
  has_paper_trail
  belongs_to :user
  has_many :media
  has_many :projectSources
  has_many :sources , :through => :projectSources
  mount_uploader :lead_image, ImageUploader
end
