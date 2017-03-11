class TeamUser < ActiveRecord::Base

  belongs_to :team
  belongs_to :user

  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :team_id, message: 'already joined this team' }
  validate :user_is_member_in_slack_team

  before_validation :set_role_default_value, on: :create
  after_create :send_email_to_team_owners
  after_save :send_email_to_requestor

  notifies_slack on: :create,
                 if: proc { |tu| User.current.present? && tu.team.setting(:slack_notifications_enabled).to_i === 1 },
                 message: proc { |tu| tu.slack_notification_message },
                 channel: proc { |tu| tu.team.setting(:slack_channel) },
                 webhook: proc { |tu| tu.team.setting(:slack_webhook) }

  def self.status_types
    %w(member requested invited banned)
  end
  validates :status, included: { values: self.status_types }

  def self.role_types
    %w(owner editor journalist contributor)
  end
  validates :role, included: { values: self.role_types }

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

  def slack_notification_message
    I18n.t(:slack_create_team_user,
      user: self.user.name,
      url: self.class.to_url("#{self.team.slug}", "*#{self.team.name}*")
    )
  end

  private

  def send_email_to_team_owners
    TeamUserMailer.delay.request_to_join(self.team, self.user, CONFIG['checkdesk_client']) if self.status == 'requested'
  end

  def send_email_to_requestor
    if self.status_was === 'requested' && ['member', 'banned'].include?(self.status)
      accepted = self.status === 'member'
      TeamUserMailer.delay.request_to_join_processed(self.team, self.user, accepted, CONFIG['checkdesk_client'])
    end
  end

  def set_role_default_value
    self.role = 'contributor' if self.role.nil?
  end

  # Validate that a Slack user is part of the team's `slack_teams` setting.
  # The `slack_teams` should be a hash of the form:
  # { 'Slack team 1 id' => 'Slack team 1 name', 'Slack team 2 id' => 'Slack team 2 name', ... }
  def user_is_member_in_slack_team
    if self.user.provider == 'slack' && self.team.setting(:slack_teams)&.is_a?(Hash)
      if self.team.setting(:slack_teams)&.keys&.include? self.user.omniauth_info&.dig('info', 'team_id')
        # Auto-approve slack user
        self.status = 'member'
      else
        params = {
          default: "Sorry, you cannot join %{team_name} because it is restricted to members of the Slack team(s) %{teams}.",
          team_name: self.team.name,
          teams: self.team.setting(:slack_teams).values.join(', ')
        }
        errors.add(:base, I18n.t(:slack_restricted_join_to_members, params))
      end
    end
  end
end
