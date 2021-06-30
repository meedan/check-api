PublicTeamType = GraphqlCrudOperations.define_default_type do
  name 'PublicTeam'
  description 'Public team type'

  implements NodeIdentification.interface

  field :name, String, null: false
  field :slug, String, null: false
  field :description, String, null: true
  field :dbid, Integer, null: true
  field :avatar, String, null: true
  field :private, Boolean, null: true
  field :team_graphql_id, String, null: true

  field :pusher_channel, String, null: true

  def pusher_channel
    Team.find(object.id).pusher_channel
  end

  instance_exec :trash_count, &GraphqlCrudOperations.archived_count
  instance_exec :unconfirmed_count, &GraphqlCrudOperations.archived_count
end
