module Types
  class CheckSearchType < DefaultObject
    description "CheckSearch type"

    implements GraphQL::Types::Relay::NodeField

    field :number_of_results, Integer, null: true
    field :pusher_channel, String, null: true
    field :item_navigation_offset, Integer, null: true
    field :team, TeamType, null: true

    field :medias,
          ProjectMediaType.connection_type,
          null: true,
          connection: true
  end
end
