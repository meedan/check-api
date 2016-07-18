TeamType = GraphQL::ObjectType.define do
  name 'Team'
  description 'Team type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('Team')
  field :updated_at, types.String
  field :created_at, types.String
  field :archived, types.Boolean
  field :logo, types.String
  field :name, types.String
  field :description, !types.String
  connection :team_users, -> { TeamUserType.connection_type } do
    resolve ->(team, _args, _ctx) {
      team.team_users
    }
  end

  connection :users, UserType.connection_type do
    resolve -> (team, _args, _ctx) {
      team.users
    }
  end
# End of fields
end
