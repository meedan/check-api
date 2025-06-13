class AddArticleSavedSearchToFeeds < ActiveRecord::Migration[6.1]
  def change
    add_reference :feeds, :article_saved_search, foreign_key: { to_table: :saved_searches }
  end
end
