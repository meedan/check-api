UserType = GraphqlCrudOperations.define_default_type do
  name 'User'
  description 'A user of the application.'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int, 'Database id of this record'
  field :email, types.String, 'Email'
  field :unconfirmed_email, types.String, 'Email before confirmation'
  field :providers, JsonStringType, 'TODO'
  field :uuid, types.String, 'TODO'
  field :profile_image, types.String, 'Picture' # TODO Rename to 'picture'
  field :login, types.String, 'Login'
  field :name, types.String, 'Name'
  field :current_team_id, types.Int, 'Current team (id only)'
  field :permissions, types.String, 'CRUD permissions for current user'
  field :jsonsettings, types.String # TODO What's the difference with 'settings'?
  field :number_of_teams, types.Int # TODO Remove because client can just count 'team_ids'?

  # TODO Review notification settings to be extensible
  field :get_send_email_notifications, types.Boolean, 'Setting for receiving email notifications about item activity'
  field :get_send_successful_login_notifications, types.Boolean, 'Setting for receiving email notifications about all login activity'
  field :get_send_failed_login_notifications, types.Boolean, 'Setting for receiving email notifications about failed login activity'

  field :bot_events, types.String, 'TODO'
  field :is_bot, types.Boolean, 'Is this user a bot?'
  field :is_active, types.Boolean, 'Is this user active?'
  field :two_factor, JsonStringType, 'TODO'
  field :settings, JsonStringType, 'Settings' # TODO Show setting schema in description
  field :accepted_terms, types.Boolean # TODO Remove because 'last_accepted_terms_at' is enough
  field :last_accepted_terms_at, types.String, 'Last date at which the user accepted the terms of use' # TODO Change to Int type
  field :team_ids, types[types.Int], 'Teams where this user is a member (ids only)'
  field :user_teams, types.String, # TODO What's this in relation to above and to 'team_users'

  field :source_id do
    type types.Int
    description 'User source profile (id only)'

    resolve -> (user, _args, _ctx) do
      user.source_id
    end
  end

  field :source do
    type SourceType
    description 'User source profile'

    resolve -> (user, _args, _ctx) do
      Source.find(user.source_id)
    end
  end

  field :token do
    type types.String
    description 'TODO'

    resolve -> (user, _args, _ctx) do
      user.token if user == User.current
    end
  end

  field :is_admin do
    type types.Boolean
    description 'Is user an application admin?'

    resolve -> (user, _args, _ctx) do
      user.is_admin if user == User.current
    end
  end

  field :current_project do
    type ProjectType
    description 'Current project'

    resolve -> (user, _args, _ctx) do
      user.current_project
    end
  end

  # TODO Rename to 'is_confirmed'
  field :confirmed do
    type types.Boolean
    description 'Has user confirmed their email?'

    resolve -> (user, _args, _ctx) do
      user.is_confirmed?
    end
  end

  field :current_team do
    type TeamType
    description 'Current team'

    resolve -> (user, _args, _ctx) do
      user.current_team
    end
  end

  field :bot do
    type BotUserType
    description 'BotUser information about this user'

    resolve -> (user, _args, _ctx) do
      user if user.is_bot
    end
  end

  # TODO Remove this and keep 'team_users'
  connection :teams, -> { TeamType.connection_type } do
    resolve ->(user, _args, _ctx) {
      user.teams
    }
  end

  connection :team_users, -> { TeamUserType.connection_type } do
    description 'Teams where this user is a member'

    resolve ->(user, _args, _ctx) {
      user.team_users
    }
  end

  # TODO Review usage
  connection :annotations, -> { AnnotationType.connection_type } do
    argument :type, types.String # TODO Consider enum type https://graphql.org/learn/schema/#enumeration-types
    description 'Annotations made by this user'

    resolve ->(user, args, _ctx) {
      type = args['type']
      type.blank? ? user.annotations : user.annotations(type)
    }
  end

  connection :assignments, -> { ProjectMediaType.connection_type } do
    argument :team_id, types.Int
    description 'Assignments for this user'

    resolve ->(user, args, _ctx) {
      # TODO Better implementation:
      # - single query
      # - use current team if argument is blank
      # - add argument for all / open / closed
      pms = Annotation.project_media_assigned_to_user(user).order('id DESC')
      team_id = args['team_id'].to_i
      pms = pms.where(team_id: team_id) if team_id > 0
      # TODO Remove finished items
      # pms.reject { |pm| pm.is_finished? }
      pms
    }
  end
end
