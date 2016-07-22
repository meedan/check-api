class Source < ActiveRecord::Base
  attr_accessible
  has_paper_trail on: [:create, :update]
  has_many :accounts
  has_many :project_sources
  has_many :projects , through: :project_sources
  belongs_to :user

  has_annotations

  mount_uploader :avatar, ImageUploader
  validates_presence_of :name, :slogan

  def user_id_callback(value, _mapping_ids = nil)
    user = User.where(email: value).last
    user.nil? ? nil : user.id
  end

  def medias
    Media.where(account_id: self.account_ids)
  end

  def image
    self.user.nil? ? self.avatar.to_s : self.user.profile_image
  end

  def collaborators
    self.annotators
  end
end
