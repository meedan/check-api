class CreateRelationship < ActiveRecord::Migration[4.2]
  def change
    create_table :relationships do |t|
      t.integer :source_id, null: false
      t.integer :target_id, null: false
      t.string :relationship_type, null: false
      t.timestamps null: false
    end

    add_index :relationships, :source_id
    add_index :relationships, :target_id
    add_index :relationships, [:source_id, :target_id]
    add_index :relationships, [:source_id, :target_id, :relationship_type], unique: true, name: 'relationship_index'
  end
end
