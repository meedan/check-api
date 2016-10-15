class Bot < ActiveRecord::Base
  attr_accessible :name, :avatar

  mount_uploader :avatar, ImageUploader
  validates_presence_of :name

  def profile_image
    CONFIG['checkdesk_base_url'] + self.avatar.url
  end
end
