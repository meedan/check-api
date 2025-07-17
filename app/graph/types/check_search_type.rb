class CheckSearchType < DefaultObject
  description "CheckSearch type"

  implements GraphQL::Types::Relay::Node

  field :number_of_results, GraphQL::Types::Int, null: true
  field :item_navigation_offset, GraphQL::Types::Int, null: true
  field :team, TeamType, null: true
  field :medias, ProjectMediaType.connection_type, null: true
end
