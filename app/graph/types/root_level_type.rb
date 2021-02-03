RootLevelType = GraphQL::ObjectType.define do
  name 'RootLevel'
  description 'Unassociated root object queries'

  interfaces [NodeIdentification.interface]

  global_id_field :id

  field :current_user, UserType do
    resolve -> (_object, _args, _ctx) {
      User.current
    }
  end

  field :current_team, TeamType do
    resolve -> (_object, _args, _ctx) {
      Team.current
    }
  end

  connection :team_bots_approved, BotUserType.connection_type do
    resolve -> (_object, _args, _ctx) {
      BotUser.all.select{ |b| b.get_approved }
    }
  end
end
