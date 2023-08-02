class CreateProjectMedias < ActiveRecord::Migration[4.2]
  def change
    create_table :project_medias do |t|
      t.belongs_to :project, index: true
      t.belongs_to :media, index: true
      t.belongs_to :user, index: true
      t.belongs_to :source, index: true
      t.belongs_to :cluster, index: true
      t.integer :team_id
      t.jsonb :channel, index: true, default: { main:0 }
      t.boolean :read, default: false, null: false
      t.integer :sources_count, null: false, default: 0
      t.integer :archived, default: 0
      t.integer :targets_count, null: false, default: 0
      t.integer :last_seen, index: true
      t.timestamps null: false
    end
    add_index :project_medias, [:team_id, :archived, :sources_count]
  end
end
