TeamUserType = GraphqlCrudOperations.define_default_type do
  name 'TeamUser'
  description 'Membership of a user in a team.'

  interfaces [NodeIdentification.interface]

  field :user_id, types.Int, 'User database id'
  field :team_id, types.Int, 'Team database id'
  field :status, types.String, 'Membership status' # TODO Enum
  field :role, types.String, 'User role in team' # TODO Enum

  field :team, TeamType, 'Team' do
    resolve -> (team_user, _args, _ctx) {
      team_user.team
    }
  end

  field :user, UserType, 'User' do
    resolve -> (team_user, _args, _ctx) {
      team_user.user
    }
  end

  field :permissions, types.String, 'CRUD permissions of this record for current user'
end
