class CreateRelationship < ActiveRecord::Migration
  def change
    create_table :relationships do |t|
      t.integer :source_id, null: false
      t.integer :target_id, null: false
      t.string :kind, null: false
      t.text :flags
      t.timestamps null: false
    end

    add_index :relationships, :source_id
    add_index :relationships, :target_id
    add_index :relationships, [:source_id, :target_id]
  end
end
