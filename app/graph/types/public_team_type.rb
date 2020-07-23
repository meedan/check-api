PublicTeamType = GraphqlCrudOperations.define_default_type do
  name 'PublicTeam'
  description 'Public team type'

  interfaces [NodeIdentification.interface]

  field :name, !types.String
  field :slug, !types.String
  field :description, types.String
  field :dbid, types.Int
  field :avatar, types.String
  field :private, types.Boolean
  field :team_graphql_id, types.String

  field :pusher_channel do
    type types.String

    resolve -> (team, _args, _ctx) do
      Team.find(team.id).pusher_channel
    end
  end

  field :trash_count, types.Int do
    resolve ->(team, _args, _ctx) {
      (team.private && (!User.current || (!User.current.is_admin && TeamUser.where(team_id: team.id, user_id: User.current.id).last.nil?))) ? 0 : team.trash_count
    }
  end
end
