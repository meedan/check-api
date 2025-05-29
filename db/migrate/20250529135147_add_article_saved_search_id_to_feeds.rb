class AddArticleSavedSearchIdToFeeds < ActiveRecord::Migration[6.1]
  def change
    add_reference :feeds, :article_saved_search_id, foreign_key: { to_table: :saved_searches }
  end
end
