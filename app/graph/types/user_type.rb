class UserType < DefaultObject
  description "User type"

  implements NodeIdentification.interface

  field :dbid, GraphQL::Types::Integer, null: true
  field :email, GraphQL::Types::String, null: true
  field :unconfirmed_email, GraphQL::Types::String, null: true
  field :providers, JsonString, null: true
  field :uuid, GraphQL::Types::String, null: true
  field :profile_image, GraphQL::Types::String, null: true
  field :login, GraphQL::Types::String, null: true
  field :name, GraphQL::Types::String, null: true
  field :current_team_id, GraphQL::Types::Integer, null: true
  field :permissions, GraphQL::Types::String, null: true
  field :jsonsettings, GraphQL::Types::String, null: true
  field :number_of_teams, GraphQL::Types::Integer, null: true
  field :get_send_email_notifications, GraphQL::Types::Boolean, null: true

  def get_send_email_notifications
    obj.get_send_email_notifications
  end

  field :get_send_successful_login_notifications, GraphQL::Types::Boolean, null: true

  def get_send_successful_login_notifications
    obj.get_send_successful_login_notifications
  end

  field :get_send_failed_login_notifications, GraphQL::Types::Boolean, null: true

  def get_send_failed_login_notifications
    obj.get_send_failed_login_notifications
  end

  field :bot_events, GraphQL::Types::String, null: true
  field :is_bot, GraphQL::Types::Boolean, null: true
  field :is_active, GraphQL::Types::Boolean, null: true
  field :two_factor, JsonString, null: true
  field :settings, JsonString, null: true
  field :accepted_terms, GraphQL::Types::Boolean, null: true
  field :last_accepted_terms_at, GraphQL::Types::String, null: true
  field :team_ids, [Integer, null: true], null: true
  field :user_teams, GraphQL::Types::String, null: true
  field :last_active_at, GraphQL::Types::Integer, null: true
  field :completed_signup, GraphQL::Types::Boolean, null: true

  field :source_id, GraphQL::Types::Integer, null: true

  def source_id
    object.source.id
  end

  field :token, GraphQL::Types::String, null: true

  def token
    object.token if object == User.current
  end

  field :is_admin, GraphQL::Types::Boolean, null: true

  def is_admin
    object.is_admin if object == User.current
  end

  field :current_project, ProjectType, null: true

  def current_project
    object.current_project
  end

  field :confirmed, GraphQL::Types::Boolean, null: true

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
    argument :team_slug, GraphQL::Types::String, required: true
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
    argument :status, GraphQL::Types::String, required: false
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
    argument :type, GraphQL::Types::String, required: false
  end

  def annotations(**args)
    type = args[:type]
    type.blank? ? object.annotations : object.annotations(type)
  end

  field :assignments,
        "ProjectMediaType",
        connection: true,
        null: true do
    argument :team_id, GraphQL::Types::Integer, required: false
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
