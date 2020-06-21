TeamType = GraphqlCrudOperations.define_default_type do
  name 'Team'
  description 'Team type'

  interfaces [NodeIdentification.interface]

  field :archived, types.Boolean
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
  field :get_slack_channel, types.String
  field :get_embed_whitelist, types.String
  field :get_report_design_image_template, types.String
  field :get_status_target_turnaround, types.String
  field :pusher_channel, types.String
  field :search_id, types.String
  field :search, CheckSearchType
  field :check_search_trash, CheckSearchType
  field :trash_size, JsonStringType
  field :public_team_id, types.String
  field :permissions_info, JsonStringType
  field :invited_mails, JsonStringType
  field :dynamic_search_fields_json_schema, JsonStringType
  field :get_rules, JsonStringType
  field :rules_json_schema, types.String
  field :rules_search_fields_json_schema, JsonStringType
  field :medias_count, types.Int
  field :trash_count, types.Int
  field :get_languages, types.String
  field :get_language, types.String
  field :get_report, JsonStringType

  field :public_team do
    type PublicTeamType

    resolve -> (team, _args, _ctx) do
      team
    end
  end

  field :verification_statuses do
    type JsonStringType

    resolve -> (team, _args, _ctx) do
      team.send('verification_statuses', 'media')
    end
  end

  connection :team_users, -> { TeamUserType.connection_type } do
    resolve -> (team, _args, _ctx) {
      team.team_users.where({ status: 'member' }).order('id ASC')
    }
  end

  connection :join_requests, -> { TeamUserType.connection_type } do
    resolve -> (team, _args, _ctx) {
      team.team_users.where({ status: 'requested' })
    }
  end

  connection :users, -> { UserType.connection_type } do
    resolve -> (team, _args, _ctx) {
      team.users
    }
  end

  connection :contacts, -> { ContactType.connection_type } do
    resolve -> (team, _args, _ctx) {
      team.contacts
    }
  end

  connection :projects, -> { ProjectType.connection_type } do
    resolve ->(team, _args, _ctx) {
      team.recent_projects
    }
  end

  connection :sources, -> { SourceType.connection_type } do
    resolve ->(team, _args, _ctx) {
      team.sources
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
    resolve ->(team, _args, _ctx) {
      team.team_tasks.order(order: :asc)
    }
  end
end
