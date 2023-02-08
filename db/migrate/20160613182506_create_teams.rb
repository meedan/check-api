class CreateTeams < ActiveRecord::Migration[4.2]
  def change
    create_table :teams do |t|
      t.string :name
      t.string :logo
      t.boolean :private, default: true
      t.integer :archived, default: 0, index: true
      t.string :country, index: true
      t.text :description
      t.string :slug
      t.boolean :inactive, default: false, index: true
      t.text :settings
      t.timestamps null: false
    end
    add_index :teams, :slug, unique: true, name: 'unique_team_slugs'
  end
end
