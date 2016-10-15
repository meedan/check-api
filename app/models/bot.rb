class Bot < ActiveRecord::Base

  mount_uploader :avatar, ImageUploader
  validates_presence_of :name

  def profile_image
    CONFIG['checkdesk_base_url'] + self.avatar.url
  end

end
