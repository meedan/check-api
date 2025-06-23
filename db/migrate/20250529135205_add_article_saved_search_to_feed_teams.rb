class AddArticleSavedSearchToFeedTeams < ActiveRecord::Migration[6.1]
  def change
    add_reference :feed_teams, :article_saved_search, foreign_key: { to_table: :saved_searches }
  end
end
