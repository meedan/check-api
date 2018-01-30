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
  field :permissions, types.String
  field :get_slack_notifications_enabled, types.String
  field :get_slack_webhook, types.String
  field :get_slack_channel, types.String
  field :get_suggested_tags, types.String
  field :get_embed_whitelist, types.String
  field :pusher_channel, types.String
  field :search_id, types.String
  field :trash_size, JsonStringType
  field :limits, JsonStringType
  field :public_team_id, types.String

  field :media_verification_statuses do
    type types.String

    resolve -> (team, _args, _ctx) {
      team.verification_statuses(:media)
    }
  end

  field :source_verification_statuses do
    type types.String

    resolve -> (team, _args, _ctx) {
      team.verification_statuses(:source)
    }
  end

  connection :team_users, -> { TeamUserType.connection_type } do
    resolve -> (team, _args, _ctx) {
      team.team_users
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
end
