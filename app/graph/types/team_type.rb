TeamType = GraphqlCrudOperations.define_default_type do
  name 'Team'
  description 'Team type'

  interfaces [NodeIdentification.interface]

  field :archived, types.Int
  field :private, types.Boolean
  field :avatar, types.String
  field :name, !types.String
  field :slug, !types.String
  field :description, types.String
  field :dbid, types.Int
  field :members_count, types.Int
  field :projects_count, types.Int
  field :permissions, types.String
  field :get_slack_notifications_enabled, types.String
  field :get_slack_webhook, types.String
  field :get_embed_whitelist, types.String
  field :get_report_design_image_template, types.String
  field :get_status_target_turnaround, types.String
  field :pusher_channel, types.String
  field :search_id, types.String
  field :search, CheckSearchType
  field :check_search_trash, CheckSearchType
  field :check_search_unconfirmed, CheckSearchType
  field :check_search_spam, CheckSearchType
  field :trash_size, JsonStringType
  field :public_team_id, types.String
  field :permissions_info, JsonStringType
  field :dynamic_search_fields_json_schema, JsonStringType
  field :get_slack_notifications, JsonStringType
  field :get_rules, JsonStringType
  field :rules_json_schema, types.String
  field :slack_notifications_json_schema, types.String
  field :rules_search_fields_json_schema, JsonStringType
  field :medias_count, types.Int
  field :spam_count, types.Int
  field :trash_count, types.Int
  field :unconfirmed_count, types.Int
  field :get_languages, types.String
  field :get_language, types.String
  field :get_report, JsonStringType
  field :get_fieldsets, JsonStringType
  field :list_columns, JsonStringType
  field :get_data_report_url, types.String
  field :url, types.String
  field :get_tipline_inbox_filters, JsonStringType
  field :get_suggested_matches_filters, JsonStringType
  field :get_trends_filters, JsonStringType
  field :get_trends_enabled, types.Boolean
  field :country, types.String
  field :country_teams, JsonStringType
  field :data_report, JsonStringType

  field :public_team do
    type PublicTeamType

    resolve -> (team, _args, _ctx) do
      team
    end
  end

  field :verification_statuses do
    type JsonStringType
    argument :items_count, types.Boolean
    argument :published_reports_count, types.Boolean

    resolve -> (team, args, _ctx) do
      team = team.reload if args['items_count'] || args['published_reports_count']
      team.send('verification_statuses', 'media', nil, args['items_count'], args['published_reports_count'])
    end
  end

  field :team_bot_installation do
    type TeamBotInstallationType
    argument :bot_identifier, !types.String

    resolve -> (team, args, _ctx) do
      TeamBotInstallation.where(user_id: BotUser.get_user(args['bot_identifier'])&.id, team_id: team.id).first
    end
  end

  connection :team_users, -> { TeamUserType.connection_type } do
    argument :status, types[types.String]

    resolve -> (team, args, _ctx) {
      status = args['status'] || 'member'
      team.team_users.where({ status: status }).order('id ASC')
    }
  end

  connection :join_requests, -> { TeamUserType.connection_type } do
    resolve -> (team, _args, _ctx) { team.team_users.where({ status: 'requested' }) }
  end

  connection :users, -> { UserType.connection_type } do
    resolve -> (team, _args, _ctx) {
      team.users
    }
  end

  connection :projects, -> { ProjectType.connection_type } do
    resolve ->(team, _args, _ctx) {
      team.recent_projects.allowed(team)
    }
  end

  field :sources_count, types.Int do
    argument :keyword, types.String

    resolve ->(team, args, _ctx) {
      team.sources_by_keyword(args['keyword']).count
    }
  end

  connection :sources, -> { SourceType.connection_type } do
    argument :keyword, types.String

    resolve ->(team, args, _ctx) {
      team.sources_by_keyword(args['keyword'])
    }
  end

  connection :team_bots, -> { BotUserType.connection_type } do
    resolve ->(team, _args, _ctx) {
      team.team_bots
    }
  end

  connection :team_bot_installations, -> { TeamBotInstallationType.connection_type } do
    resolve ->(team, _args, _ctx) {
      team.team_bot_installations
    }
  end

  connection :tag_texts, -> { TagTextType.connection_type } do
    resolve ->(team, _args, _ctx) {
      team.tag_texts
    }
  end

  connection :team_tasks, -> { TeamTaskType.connection_type } do
    argument :fieldset, types.String

    resolve ->(team, args, _ctx) {
      tasks = team.team_tasks.order(order: :asc, id: :asc)
      tasks = tasks.where(fieldset: args['fieldset']) unless args['fieldset'].blank?
      tasks
    }
  end

  field :team_task do
    type TeamTaskType
    argument :dbid, !types.Int

    resolve -> (team, args, _ctx) { team.team_tasks.where(id: args['dbid']).first }
  end

  field :default_folder do
    type ProjectType

    resolve -> (team, _args, _ctx) { team.default_folder }
  end

  connection :saved_searches, SavedSearchType.connection_type
  connection :project_groups, ProjectGroupType.connection_type
end
