class CheckSearchType < DefaultObject
  description "CheckSearch type"

  implements NodeIdentification.interface

  field :number_of_results, Integer, null: true
  field :pusher_channel, String, null: true
  field :item_navigation_offset, Integer, null: true
  field :team, TeamType, null: true

  field :medias,
        ProjectMediaType.connection_type,
        null: true
end
