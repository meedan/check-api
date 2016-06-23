TeamUserType = GraphQL::ObjectType.define do
  name 'TeamUser'
  description 'TeamUser type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('TeamUser')
  field :updated_at, types.String
  field :created_at, types.String
  field :user_id, types.Int
  field :team_id, types.Int
  field :team do
    type -> { TeamType }

    resolve -> (team_user, _args, _ctx) {
      team_user.team
    }
  end

  field :user do
    type UserType

    resolve -> (team_user, _args, _ctx) {
      team_user.user
    }
  end
# End of fields
end
