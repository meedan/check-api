UserType = GraphqlCrudOperations.define_default_type do
  name 'User'
  description 'A user of the application.'

  interfaces [NodeIdentification.interface]

  field :email, types.String, 'Email'
  field :unconfirmed_email, types.String, 'Email before confirmation'
  field :providers, JsonStringType # TODO Document
  field :uuid, types.String # TODO Document
  field :profile_image, types.String, 'Picture' # TODO Rename to 'picture'
  field :login, types.String, 'Login'
  field :name, types.String, 'Name'
  field :current_team_id, types.Int, 'Current team database id'
  field :jsonsettings, types.String # TODO What's the difference with 'settings'?
  field :number_of_teams, types.Int # TODO Remove because client can just count 'team_ids'?

  # TODO Review notification settings to be extensible
  field :get_send_email_notifications, types.Boolean, 'Setting for receiving email notifications about item activity'
  field :get_send_successful_login_notifications, types.Boolean, 'Setting for receiving email notifications about all login activity'
  field :get_send_failed_login_notifications, types.Boolean, 'Setting for receiving email notifications about failed login activity'

  field :bot_events, types.String # TODO Why is this here?
  field :is_bot, types.Boolean, 'Is this user a bot?'
  field :is_active, types.Boolean, 'Is this user active?'
  field :two_factor, JsonStringType # TODO Document
  field :settings, JsonStringType, 'Settings' # TODO Show setting schema in description
  field :accepted_terms, types.Boolean, 'Has use accepted latest terms?' # TODO Rename to 'has_accepted_latest_terms'
  field :last_accepted_terms_at, types.String, 'Last date at which the user accepted the terms of use' # TODO Change to Int type
  field :team_ids, types[types.Int], 'Teams where this user is a member (ids only)'
  field :user_teams, types.String # TODO What's this in relation to above and to 'team_users'?

  field :source_id, types.Int, 'User source profile database id' do
    resolve -> (user, _args, _ctx) do
      user.source_id
    end
  end

  field :source, SourceType, 'User source profile' do
    resolve -> (user, _args, _ctx) do
      user.source
    end
  end

  field :token, types.String, 'Security token (current user only)' do
    resolve -> (user, _args, _ctx) do
      user.token if user == User.current
    end
  end

  field :is_admin, types.Boolean, 'Is user an application admin? (current user only)' do
    resolve -> (user, _args, _ctx) do
      user.is_admin if user == User.current
    end
  end

  field :current_project, ProjectType, 'Current project' do
    resolve -> (user, _args, _ctx) do
      user.current_project
    end
  end

  # TODO Rename to 'is_confirmed'
  field :confirmed, types.Boolean, 'Has user confirmed their email?' do
    resolve -> (user, _args, _ctx) do
      user.is_confirmed?
    end
  end

  field :current_team, TeamType, 'Current team' do
    resolve -> (user, _args, _ctx) do
      user.current_team
    end
  end

  field :bot, BotUserType, 'BotUser information about this user' do
    resolve -> (user, _args, _ctx) do
      user if user.is_bot
    end
  end

  connection :teams, -> { TeamType.connection_type }, 'Teams where this user is a member' do
    resolve -> (user, _args, _ctx) do
      user.teams
    end
  end

  field :team_user, TeamUserType, 'Team membership of this user' do
    argument :team_slug, !types.String, 'Team slug to match (required)'

    resolve ->(user, args, _ctx) {
      TeamUser.joins(:team).where('teams.slug' => args['team_slug'], user_id: user.id).last
    }
  end

  connection :team_users, -> { TeamUserType.connection_type }, 'Team memberships of this user' do
    argument :status, types.String, 'Member status to match (optional)'

    resolve -> (user, args, _ctx) do
      team_users = user.team_users
      team_users = team_users.where(status: args['status']) if args['status']
      team_users
    end
  end

  # TODO Review usage
  connection :annotations, -> { AnnotationType.connection_type }, 'Annotations made by this user' do
    argument :type, types.String, 'Annotation type to match' # TODO Consider enum type https://graphql.org/learn/schema/#enumeration-types

    resolve -> (user, args, _ctx) do
      args['type'].blank? ? user.annotations : user.annotations(args['type'])
    end
  end

  connection :assignments, -> { ProjectMediaType.connection_type }, 'Assignments for this user' do
    argument :team_id, types.Int, 'Database id of team to match'

    resolve -> (user, args, _ctx) do
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
    end
  end

  field :dbid, types.Int, 'Database id of this record'
  field :permissions, types.String, 'CRUD permissions of this record for current user'
end
