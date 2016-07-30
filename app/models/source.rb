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
    user_callback(value)
  end

  def avatar_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def medias
    Media.where(account_id: self.account_ids)
  end

  def image
    self.user.nil? ? self.avatar.to_s : self.user.profile_image
  end

  def description
    return self.slogan unless self.slogan == self.name
    self.accounts.first.data['description'] unless self.accounts.empty?
  end

  def collaborators
    self.annotators
  end

  def tags
    self.annotations('tag')
  end

  def comments
    self.annotations('comment')
  end
end
