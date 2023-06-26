class CheckSearchType < DefaultObject
  description "CheckSearch type"

  implements NodeIdentification.interface

  field :number_of_results, GraphQL::Types::Integer, null: true
  field :pusher_channel, GraphQL::Types::String, null: true
  field :item_navigation_offset, GraphQL::Types::Integer, null: true
  field :team, TeamType, null: true

  field :medias,
        ProjectMediaType.connection_type,
        null: true
end
