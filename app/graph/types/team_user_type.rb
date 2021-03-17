TeamUserType = GraphqlCrudOperations.define_default_type do
  name 'TeamUser'
  description 'TeamUser type'

  interfaces [NodeIdentification.interface]

  field :dbid, types.Int
  field :user_id, types.Int
  field :team_id, types.Int
  field :status, types.String
  field :role, types.String
  field :permissions, types.String

  field :team do
    type TeamType

    resolve -> (team_user, _args, _ctx) { team_user.team }
  end

  field :user do
    type UserType

    resolve -> (team_user, _args, _ctx) {
      team_user.user
    }
  end

  field :invited_by do
    type UserType

    resolve -> (team_user, _args, _ctx) {
      User.find_by_id(team_user.invited_by_id)
    }
  end
end
