class RenameSavedSearchIdToMediaSavedSearchId < ActiveRecord::Migration[6.1]
  def change
    rename_column :feeds, :saved_search_id, :media_saved_search_id
    rename_column :feed_teams, :saved_search_id, :media_saved_search_id
  end
end
