class SavedSearchType < DefaultObject
  description "Saved search type"

  implements GraphQL::Types::Relay::Node

  field :dbid, GraphQL::Types::Int, null: true
  field :title, GraphQL::Types::String, null: true
  field :team_id, GraphQL::Types::Int, null: true
  field :team, PublicTeamType, null: true
  field :items_count, GraphQL::Types::Int, null: true
  field :list_type, GraphQL::Types::String, null: true
  field :filters, GraphQL::Types::String, null: true

  def filters
    object.filters ? object.filters.to_json : "{}"
  end

  field :is_part_of_feeds, GraphQL::Types::Boolean, null: true

  def is_part_of_feeds
    Feed.where(saved_search_id: object.id).exists? || FeedTeam.where(saved_search_id: object.id).exists?
  end

  field :feeds, FeedType.connection_type, null: true

  def feeds
    Feed.where(saved_search_id: object.id)
  end
end
