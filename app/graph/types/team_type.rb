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
  field :get_suggested_tags, types.String
  field :get_embed_whitelist, types.String
  field :get_memebuster_template, types.String
  field :pusher_channel, types.String
  field :search_id, types.String
  field :trash_size, JsonStringType
  field :limits, JsonStringType
  field :public_team_id, types.String
  field :plan, types.String
  field :used_tags, types.String.to_list_type
  field :permissions_info, JsonStringType
  field :invited_mails, JsonStringType

  connection :team_users, -> { TeamUserType.connection_type } do
    resolve -> (team, _args, _ctx) {
      team.team_users.where({ status: 'member' })
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

  connection :team_bots, -> { TeamBotType.connection_type } do
    resolve ->(team, _args, _ctx) {
      team.team_bots
    }
  end

  connection :team_bot_installations, -> { TeamBotInstallationType.connection_type } do
    resolve ->(team, _args, _ctx) {
      team.team_bot_installations
    }
  end

  connection :teamwide_tags, -> { TagTextType.connection_type } do
    resolve ->(team, _args, _ctx) {
      team.teamwide_tags
    }
  end

  connection :custom_tags, -> { TagTextType.connection_type } do
    resolve ->(team, _args, _ctx) {
      team.custom_tags
    }
  end

  connection :team_tasks, -> { TeamTaskType.connection_type } do
    resolve ->(team, _args, _ctx) {
      team.team_tasks.order('id ASC')
    }
  end
end
