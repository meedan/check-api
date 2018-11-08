class TeamUser < ActiveRecord::Base

  belongs_to :team
  belongs_to :user

  validates_presence_of :team, :user

  validates :status, presence: true
  validates :user_id, uniqueness: { scope: :team_id, message: 'already joined this team' }
  validate :user_is_member_in_slack_team

  before_validation :set_role_default_value, on: :create
  after_create :send_email_to_team_owners, :send_slack_notification
  after_update :send_slack_notification
  after_save :send_email_to_requestor, :update_user_cached_teams_after_save
  after_destroy :update_user_cached_teams_after_destroy

  def self.status_types
    %w(member requested invited banned)
  end
  validates :status, included: { values: self.status_types }

  def self.role_types
    %w(owner editor journalist contributor annotator)
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

  def slack_params
    user = self.user
    {
      user: Bot::Slack.to_slack(user.name),
      user_image: user.profile_image,
      team: Bot::Slack.to_slack(self.team.name),
      url: "#{CONFIG['checkdesk_client']}/check/user/#{user.id}",
      description: Bot::Slack.to_slack(user.source&.description, false),
      button: I18n.t("slack.fields.view_button", {
        type: I18n.t("activerecord.models.user"), app: CONFIG['app_name']
      })
    }
  end

  def slack_notification_message
    # Ignore updates that don't involve the status. The presence of "id" indicates creation.
    return nil if (self.changed & ['id', 'status']).blank?

    params = self.slack_params
    {
      pretext: I18n.t("slack.messages.user_#{self.status}", params),
      title: params[:project],
      title_link: params[:url],
      author_name: params[:user],
      author_icon: params[:user_image],
      text: params[:description],
      actions: [
        {
          type: "button",
          text: params[:button],
          url: params[:url]
        }
      ]
    }
  end

  def is_being_copied
    self.team && self.team.is_being_copied
  end

  # Copy invitation_period_valid? & invitation_due_at from devise_invitable

  def invitation_period_valid?
    time = self.created_at
    self.user.class.invite_for.to_i.zero? || (time && time.utc >= self.user.class.invite_for.ago)
  end

  def invitation_due_at
    return nil if (self.user.class.invite_for == 0 || self.user.class.invite_for.nil?)
    time = self.created_at
    time + self.user.class.invite_for
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
    return if self.is_being_copied
    TeamUserMailer.delay.request_to_join(self.team, self.user, CONFIG['checkdesk_client']) if self.status == 'requested'
  end

  def send_email_to_requestor
    return if self.is_being_copied
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
