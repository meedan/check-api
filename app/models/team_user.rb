class TeamUser < ActiveRecord::Base

  belongs_to :team
  belongs_to :user

  validates_presence_of :team, :user

  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :team_id, message: 'already joined this team' }
  validate :user_is_member_in_slack_team

  before_validation :set_role_default_value, on: :create
  after_create :send_email_to_team_owners, :send_slack_notification
  after_save :send_email_to_requestor, :update_user_cached_teams_after_save
  after_destroy :update_user_cached_teams_after_destroy

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
      user: Bot::Slack.to_slack(self.user.name),
      url: Bot::Slack.to_slack_url(self.team.slug, self.team.name)
    )
  end

  protected

  def update_user_cached_teams(action) # action: :add or :remove
    user = self.user
    return if user.nil?
    teams = user.cached_teams.clone
    if action == :add
      teams << self.team_id
    elsif action == :remove
      teams -= [self.team_id]
    end
    user.cached_teams = teams.uniq
    user.skip_check_ability = true
    user.save(validate: false)
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
    if !self.user.nil? && self.user.provider == 'slack' && self.team.setting(:slack_teams)&.is_a?(Hash)
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

  def update_user_cached_teams_after_save
    if self.status == 'member'
      self.update_user_cached_teams(:add)
    else # "requested" or "banned"
      self.update_user_cached_teams(:remove)
    end
  end

  def update_user_cached_teams_after_destroy
    self.update_user_cached_teams(:remove)
  end
end
