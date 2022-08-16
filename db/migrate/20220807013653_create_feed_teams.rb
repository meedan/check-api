class CreateFeedTeams < ActiveRecord::Migration[5.2]
  def change
    create_table :feed_teams do |t|
      t.references :team, null: false, foreign_key: true, index: true
      t.references :feed, null: false, foreign_key: true, index: true
      t.jsonb :filters, default: {}
      t.jsonb :settings, default: {}
      t.timestamps
    end
    add_index :feed_teams, [:team_id, :feed_id], unique: true
  end
end
