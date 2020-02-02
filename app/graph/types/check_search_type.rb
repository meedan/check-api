CheckSearchType = GraphqlCrudOperations.define_default_type do
  name 'CheckSearch'
  description 'CheckSearch type'

  interfaces [NodeIdentification.interface]

  field :number_of_results, types.Int
  field :pusher_channel, types.String
  field :item_navigation_offset, types.Int
  field :team, TeamType

  connection :medias, ProjectMediaType.connection_type
  connection :sources, ProjectSourceType.connection_type
end
