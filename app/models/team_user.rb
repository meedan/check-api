class TeamUser < ActiveRecord::Base
  attr_accessible

  belongs_to :team
  belongs_to :user

  validates :status, presence: true
  validates :status, inclusion: { in: %w(member requested invited banned), message: "%{value} is not a valid team member status" }
  validates :role, inclusion: { in: %w(admin owner editor journalist contributor), message: "%{value} is not a valid team role" }
  validates :user_id, uniqueness: { scope: :team_id, message: "User already joined this team" }

  before_validation :set_role_default_value, on: :create
  after_create :send_email_to_team_owners
  after_save :send_email_to_requestor

  notifies_slack on: :create,
                 if: proc { |tu| tu.current_user.present? && tu.team.setting(:slack_notifications_enabled).to_i === 1 },
                 message: proc { |tu| "<#{tu.origin}/user/#{tu.user.id}|*#{tu.user.name}*> joined <#{tu.origin.gsub(/(https?:\/\/[^\/]+).*/, '\1')}|*#{tu.team.name}*>" },
                 channel: proc { |tu| tu.team.setting(:slack_channel) },
                 webhook: proc { |tu| tu.team.setting(:slack_webhook) }

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def team_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def as_json(_options = {})
    {
      id: self.team.id,
      name: self.team.name,
      role: self.role,
      status: self.status
    }
  end

  private

  def send_email_to_team_owners
    TeamUserMailer.request_to_join(self.team, self.user, self.origin).deliver_now
  end

  def send_email_to_requestor
    if self.status_was === 'requested' && ['member', 'banned'].include?(self.status)
      accepted = self.status === 'member'
      TeamUserMailer.request_to_join_processed(self.team, self.user, accepted, self.origin).deliver_now
    end
  end

  def set_role_default_value
    self.role = 'contributor' if self.role.nil?
  end
end
