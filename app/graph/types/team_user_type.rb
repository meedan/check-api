TeamUserType = GraphqlCrudOperations.define_default_type do
  name 'TeamUser'
  description 'Association between a User and a Team.'

  interfaces [NodeIdentification.interface]

  field :user_id, types.Int
  field :team_id, types.Int
  field :status, types.String
  field :role, types.String
  field :permissions, types.String, 'CRUD permissions for current user'

  field :team do
    type TeamType

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
end
