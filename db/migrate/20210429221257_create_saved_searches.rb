class CreateSavedSearches < ActiveRecord::Migration[4.2]
  def change
    create_table :saved_searches do |t|
      t.string :title, null: false
      t.integer :team_id, null: false
      t.json :filters
      t.timestamps null: false
    end
    add_index :saved_searches, :team_id
  end
end
