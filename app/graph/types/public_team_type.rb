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

  instance_exec :trash_count, &GraphqlCrudOperations.archived_count
  instance_exec :unconfirmed_count, &GraphqlCrudOperations.archived_count
  instance_exec :spam_count, &GraphqlCrudOperations.archived_count

end
