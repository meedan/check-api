class Project < ActiveRecord::Base
  attr_accessible
  has_paper_trail
  belongs_to :user
  has_many :media
  has_many :project_sources
  has_many :sources , :through => :project_sources
  mount_uploader :lead_image, ImageUploader
end
