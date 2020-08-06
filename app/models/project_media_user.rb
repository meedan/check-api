class ProjectMediaUser < ActiveRecord::Base
  belongs_to :project_media
  belongs_to :user

  validates_presence_of :user_id
  validates_presence_of :project_media_id

  before_validation :set_user, on: :create
  after_save :update_project_media_read

  private

  def update_project_media_read
    pm = self.project_media
    if self.read && !pm.read
      pm.read = true
      pm.record_timestamps = false
      pm.save!
    end
  end

  def set_user
    self.user ||= User.current
  end
end
