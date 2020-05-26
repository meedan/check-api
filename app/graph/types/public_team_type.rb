PublicTeamType = GraphqlCrudOperations.define_default_type do
  name 'PublicTeam'
  description 'The public attributes of a Team.'

  interfaces [NodeIdentification.interface]

  field :name, !types.String, 'Name'
  field :slug, !types.String, 'Slug (URL path)'
  field :description, types.String, 'Description'
  field :avatar, types.String, 'Picture' # TODO Rename to 'picture'
  field :private, types.Boolean, 'Is team private?' # TODO Rename to is_private
  field :team_graphql_id, types.String # TODO Why do we need this? Rename to 'team_id'

  field :trash_count, types.Int do
    description 'Count of items in trash'

    resolve ->(team, _args, _ctx) {
      (team.private && (!User.current || (!User.current.is_admin && TeamUser.where(team_id: team.id, user_id: User.current.id).last.nil?))) ? 0 : team.trash_count
    }
  end

  field :dbid, types.Int, 'Database id of this record'

  field :pusher_channel do
    type types.String
    description 'Channel for push notifications'

    resolve -> (team, _args, _ctx) do
      Team.find(team.id).pusher_channel
    end
  end
end
