TeamType = GraphqlCrudOperations.define_default_type do
  name 'Team'
  description 'Team type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Team')
  field :updated_at, types.String
  field :created_at, types.String
  field :archived, types.Boolean
  field :private, types.Boolean
  field :avatar, types.String
  field :name, !types.String
  field :subdomain, !types.String
  field :description, types.String
  field :dbid, types.Int
  field :members_count, types.Int
  field :permissions, types.String
  field :get_slack_notifications_enabled, types.String
  field :get_slack_webhook, types.String
  field :get_slack_channel, types.String
  field :pusher_channel, types.String

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
end
