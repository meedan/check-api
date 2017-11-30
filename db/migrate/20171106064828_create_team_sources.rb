class CreateTeamSources < ActiveRecord::Migration
  def change
    create_table :team_sources do |t|
      t.belongs_to :team, index: true, foreign_key: true
      t.belongs_to :source, index: true, foreign_key: true
      t.belongs_to :user, index: true, foreign_key: true
      t.integer :cached_annotations_count, default: 0
      t.boolean :archived, default: false

      t.timestamps null: false
    end
  end
end
