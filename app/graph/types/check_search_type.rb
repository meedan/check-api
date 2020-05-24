# TODO Rename to SearchResultsType
CheckSearchType = GraphqlCrudOperations.define_default_type do
  name 'CheckSearch'
  description 'The result set for a search query.'

  interfaces [NodeIdentification.interface]

  field :number_of_results, types.Int, 'Results count' # TODO Rename to 'count_results'
  field :pusher_channel, types.String, 'Channel for push notifications'
  field :item_navigation_offset, types.Int, 'Offset into result set' # TODO Rename to 'offset'
  field :team, TeamType, 'Team where search occurred'

  connection :medias, ProjectMediaType.connection_type, 'Search results' # TODO Rename to 'results'
  connection :sources, ProjectSourceType.connection_type, 'DEPRECATED' # TODO Remove?
end
