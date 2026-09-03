class CheckDataExport < ApplicationRecord
  belongs_to :team
  belongs_to :user

  validates_presence_of :team_id, :user_id
  validates_uniqueness_of :team_id

  validate :user_is_admin_member

  private

  def user_is_admin_member
    if self.team && self.user
      errors.add(:user_id, I18n.t(:"errors.messages.check_export_data_user_must_be_admin_member")) unless self.team.team_users.where(user_id: self.user.id, role: 'admin', status: 'member').exists?
    end
  end
end
