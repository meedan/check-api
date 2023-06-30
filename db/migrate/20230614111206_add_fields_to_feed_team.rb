class AddFieldsToFeedTeam < ActiveRecord::Migration[6.1]
  def change
    add_reference :feed_teams, :saved_search, index: true
    # Remove filters column
    remove_column :feed_teams, :filters
  end
end
