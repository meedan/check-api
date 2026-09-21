class CheckDataExport < ApplicationRecord
  EXPORT_STATUS = { 'requested' => 0, 'generated' => 1, 'expired' => 2 }

  belongs_to :team
  belongs_to :user

  before_validation :set_team_and_user, on: :create

  validates_presence_of :team_id, :user_id
  validates_uniqueness_of :team_id

  validates :status, inclusion: { in: EXPORT_STATUS.keys }
  enum status: EXPORT_STATUS

  validate :user_is_admin_member

  after_create :send_request_notification, if: proc { |de| de.status == 'requested' }
  after_save :send_download_notification, if: proc { |de| de.saved_change_to_status?(from: 'requested', to: 'generated') }

  private

  def set_team_and_user
    self.user ||= User.current
    self.team ||= Team.current
  end

  def user_is_admin_member
    if self.team && self.user
      errors.add(:user_id, I18n.t(:"errors.messages.check_export_data_user_must_be_admin_member")) unless self.team.team_users.where(user_id: self.user.id, role: 'admin', status: 'member').exists?
    end
  end

  def send_request_notification
    SunsetMailer.delay.request_export_notification(self.id)
  end

  def send_download_notification
    SunsetMailer.delay.notify('download', self.user_id, self.team_id)
  end
end
