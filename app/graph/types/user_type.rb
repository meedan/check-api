class UserType < DefaultObject
  description "User type"

  implements NodeIdentification.interface

  field :dbid, Integer, null: true
  field :email, String, null: true
  field :unconfirmed_email, String, null: true
  field :providers, JsonString, null: true
  field :uuid, String, null: true
  field :profile_image, String, null: true
  field :login, String, null: true
  field :name, String, null: true
  field :current_team_id, Integer, null: true
  field :permissions, String, null: true
  field :jsonsettings, String, null: true
  field :number_of_teams, Integer, null: true
  field :get_send_email_notifications, Boolean, null: true
  field :get_send_successful_login_notifications, Boolean, null: true
  field :get_send_failed_login_notifications, Boolean, null: true
  field :bot_events, String, null: true
  field :is_bot, Boolean, null: true
  field :is_active, Boolean, null: true
  field :two_factor, JsonString, null: true
  field :settings, JsonString, null: true
  field :accepted_terms, Boolean, null: true
  field :last_accepted_terms_at, String, null: true
  field :team_ids, [Integer, null: true], null: true
  field :user_teams, String, null: true
  field :last_active_at, Integer, null: true
  field :completed_signup, Boolean, null: true

  field :source_id, Integer, null: true

  def source_id
    object.source.id
  end

  field :token, String, null: true

  def token
    object.token if object == User.current
  end

  field :is_admin, Boolean, null: true

  def is_admin
    object.is_admin if object == User.current
  end

  field :current_project, ProjectType, null: true

  def current_project
    object.current_project
  end

  field :confirmed, Boolean, null: true

  def confirmed
    object.is_confirmed?
  end

  field :source, SourceType, null: true

  def source
    Source.find(object.source_id)
  end

  field :current_team, TeamType, null: true

  def current_team
    object.current_team
  end

  field :bot, BotUserType, null: true

  def bot
    object if object.is_bot
  end

  field :team_user, TeamUserType, null: true do
    argument :team_slug, String, required: true
  end

  def team_user(**args)
    TeamUser
      .joins(:team)
      .where("teams.slug" => args[:team_slug], :user_id => object.id)
      .last
  end

  field :teams, TeamType.connection_type, null: true

  def teams
    object.teams
  end

  field :team_users,
        TeamUserType.connection_type,
        null: true do
    argument :status, String, required: false
  end

  def team_users(**args)
    team_users = object.team_users
    team_users = team_users.where(status: args[:status]) if args[:status]
    team_users
  end

  field :annotations,
        "AnnotationType",
        connection: true,
        null: true do
    argument :type, String, required: false
  end

  def annotations(**args)
    type = args[:type]
    type.blank? ? object.annotations : object.annotations(type)
  end

  field :assignments,
        "ProjectMediaType",
        connection: true,
        null: true do
    argument :team_id, Integer, required: false
  end

  def assignments(**args)
    pms = Annotation.project_media_assigned_to_user(object).order("id DESC")
    team_id = args[:team_id].to_i
    pms = pms.where(team_id: team_id) if team_id > 0
    # TODO: remove finished items
    # pms.reject { |pm| pm.is_finished? }
    pms
  end
end
