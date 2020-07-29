TeamType = GraphqlCrudOperations.define_default_type do
  name 'Team'
  description 'The team (workspace) where annotation activity occurs.'

  interfaces [NodeIdentification.interface]

  field :archived, types.Boolean # TODO Rename to 'is_archived'
  field :private, types.Boolean # TODO Rename to 'is_private'
  field :avatar, types.String, 'Picture' # TODO Rename to 'picture'
  field :name, !types.String, 'Team name'
  field :slug, !types.String, 'Team slug (URL path)'
  field :description, types.String, 'Team description'
  field :members_count, types.Int, 'Count of team members'
  field :projects_count, types.Int, 'Count of team projects (lists)'
  field :get_slack_notifications_enabled, types.String # TODO Rename to 'slack_notifications_enabled'
  field :get_slack_webhook, types.String # TODO Rename to 'slack_webhook'
  field :get_slack_channel, types.String # TODO Rename to 'slack_channel'
  field :get_embed_whitelist, types.String  # TODO Review and/or rename to 'embed_whitelist'
  field :get_report_design_image_template, types.String # TODO Merge into 'report_settings'
  field :search_id, types.String # TODO What's that for?
  field :search, CheckSearchType, 'Team search'
  field :check_search_trash, CheckSearchType # TODO Rename to 'search_trash'
  field :trash_size, JsonStringType # TODO What's that as opposed to `trash_count`?
  field :public_team_id, types.String
  field :permissions_info, JsonStringType
  field :invited_mails, JsonStringType
  field :dynamic_search_fields_json_schema, JsonStringType
  field :get_rules, JsonStringType # TODO Rename to 'rules'
  field :rules_json_schema, types.String # TODO Why not a JsonStringType?
  field :rules_search_fields_json_schema, JsonStringType # TODO What's this?
  field :medias_count, types.Int, 'Count of active items'
  field :trash_count, types.Int, 'Count of trashed items'
  field :get_languages, types.String # TODO Rename to 'languages'
  field :get_language, types.String  # TODO Rename to 'language'
  field :get_report, JsonStringType # TODO Rename to 'report_settings'

  field :public_team, PublicTeamType, 'Public team information' do
    resolve -> (team, _args, _ctx) do
      team
    end
  end

  field :verification_statuses, JsonStringType, 'Verification statuses used in this team' do
    argument :items_count, types.Boolean # TODO What's this?
    argument :published_reports_count, types.Boolean # TODO What's this?

    resolve -> (team, args, _ctx) do
      team.reload.send('verification_statuses', 'media', nil, args['items_count'], args['published_reports_count'])
    end
  end

  connection :team_users, -> { TeamUserType.connection_type }, 'Team memberships' do
    resolve -> (team, _args, _ctx) {
      team.team_users.where({ status: 'member' }).order('id ASC')
    }
  end

  connection :join_requests, -> { TeamUserType.connection_type }, 'Join requests' do
    resolve -> (team, _args, _ctx) {
      team.team_users.where({ status: 'requested' })
    }
  end

  # TODO Remove this in favor of 'team_users'
  connection :users, -> { UserType.connection_type }, 'Team members' do
    resolve -> (team, _args, _ctx) {
      team.users
    }
  end

  # TODO Merge this here
  connection :contacts, -> { ContactType.connection_type } do
    resolve -> (team, _args, _ctx) {
      team.contacts
    }
  end

  connection :projects, -> { ProjectType.connection_type }, 'Team projects (lists)' do
    resolve ->(team, _args, _ctx) {
      team.recent_projects
    }
  end

  connection :sources, -> { SourceType.connection_type }, 'Team sources' do
    resolve ->(team, _args, _ctx) {
      team.sources
    }
  end

  # TODO Remove this in favor of 'team_bots_installations'
  connection :team_bots, -> { BotUserType.connection_type }, 'Team bots' do
    resolve ->(team, _args, _ctx) {
      team.team_bots
    }
  end

  # TODO Rename to 'bots'
  connection :team_bot_installations, -> { TeamBotInstallationType.connection_type }, 'Team bots' do
    resolve ->(team, _args, _ctx) {
      team.team_bot_installations
    }
  end

  # TODO Rename this to 'tags'
  connection :tag_texts, -> { TagTextType.connection_type }, 'Team tags' do
    resolve ->(team, _args, _ctx) {
      team.tag_texts
    }
  end

  # TODO Rename this to 'tasks'
  connection :team_tasks, -> { TeamTaskType.connection_type }, 'Team tasks' do
    resolve ->(team, _args, _ctx) {
      team.team_tasks.order(order: :asc)
    }
  end

  field :dbid, types.Int, 'Database id of this record'
  field :permissions, types.String, 'CRUD permissions of this record for current user'
  field :pusher_channel, types.String, 'Channel for push notifications'
end
