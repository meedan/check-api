class AddSharedToFeedTeam < ActiveRecord::Migration[5.2]
  def change
    add_column :feed_teams, :shared, :boolean, default: false
  end
end
