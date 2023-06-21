class SavedSearchType < DefaultObject
  description "Saved search type"

  implements NodeIdentification.interface

  field :dbid, Integer, null: true
  field :title, String, null: true
  field :team_id, Integer, null: true
  field :team, TeamType, null: true

  field :filters, String, null: true

  def filters
    object.filters ? object.filters.to_json : "{}"
  end

  field :is_part_of_feeds, Boolean, null: true

  def is_part_of_feeds
    Feed.where(saved_search_id: object.id).exists?
  end

  field :feeds, FeedType.connection_type, null: true

  def feeds
    Feed.where(saved_search_id: object.id)
  end
end
