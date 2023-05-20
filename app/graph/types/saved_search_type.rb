module Types
  class SavedSearchType < DefaultObject
    description "Saved search type"

    implements GraphQL::Types::Relay::NodeField

    field :dbid, Integer, null: true
    field :title, String, null: true
    field :team_id, Integer, null: true
    field :team, TeamType, null: true

    field :filters, String, null: true

    def filters
      object.filters ? object.filters.to_json : "{}"
    end
  end
end
