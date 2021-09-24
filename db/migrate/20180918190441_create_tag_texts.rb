class CreateTagTexts < ActiveRecord::Migration[4.2]
  def change
    create_table :tag_texts do |t|
      t.string :text, null: false
      t.integer :team_id, null: false
      t.integer :tags_count, default: 0
      t.boolean :teamwide, default: false
      t.timestamps null: false
    end
    add_index :tag_texts, [:text, :team_id], unique: true
  end
end
