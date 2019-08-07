UserType = GraphqlCrudOperations.define_default_type do
  name 'User'
  description 'User type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :email, types.String
  field :unconfirmed_email, types.String
  field :providers, JsonStringType
  field :uuid, types.String
  field :profile_image, types.String
  field :login, types.String
  field :name, types.String
  field :current_team_id, types.Int
  field :permissions, types.String
  field :jsonsettings, types.String
  field :number_of_teams, types.Int
  field :get_send_email_notifications, types.Boolean
  field :get_send_successful_login_notifications, types.Boolean
  field :get_send_failed_login_notifications, types.Boolean
  field :bot_events, types.String
  field :is_bot, types.Boolean
  field :is_active, types.Boolean
  field :two_factor, JsonStringType

  field :confirmed do
    type types.Boolean
    resolve -> (user, _args, _ctx) do
      user.is_confirmed?
    end
  end

  field :source do
    type SourceType
    resolve -> (user, _args, _ctx) do
      Source.find(user.source_id)
    end
  end

  field :current_team do
    type TeamType
    resolve -> (user, _args, _ctx) do
      user.current_team
    end
  end

  field :bot do
    type BotUserType
    resolve -> (user, _args, _ctx) do
      user if user.is_bot
    end
  end

  connection :teams, -> { TeamType.connection_type } do
    resolve ->(user, _args, _ctx) {
      user.teams
    }
  end

  connection :team_users, -> { TeamUserType.connection_type } do
    resolve ->(user, _args, _ctx) {
      user.team_users
    }
  end

  connection :annotations, -> { AnnotationType.connection_type } do
    argument :type, types.String

    resolve ->(user, args, _ctx) {
      type = args['type']
      type.blank? ? user.annotations : user.annotations(type)
    }
  end

  connection :assignments, -> { ProjectMediaType.connection_type } do
    argument :team_id, types.Int

    resolve ->(user, args, _ctx) {
      pms = Annotation.project_media_assigned_to_user(user).order('id DESC')
      team_id = args['team_id'].to_i
      pms = pms.joins(:project).where('projects.team_id' => team_id) if team_id > 0
      pms.reject { |pm| pm.is_finished? }
    }
  end
end
