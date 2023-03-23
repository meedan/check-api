class CreateRelationship < ActiveRecord::Migration[4.2]
  def change
    create_table :relationships do |t|
      t.integer :source_id, null: false
      t.integer :target_id, null: false
      t.belongs_to :user
      t.string :relationship_type, null: false, index: true
      t.float :original_weight, :float, default: 0
      t.jsonb :original_details, default: '{}'
      t.string :original_relationship_type
      t.string :original_model
      t.integer :original_source_id
      t.string :original_source_field
      t.integer :confirmed_by
      t.datetime :confirmed_at
      t.float :weight, default: 0
      t.string :source_field, default: nil
      t.string :target_field, default: nil
      t.string :model, default: nil
      t.jsonb :details, default: '{}'
      t.timestamps null: false
    end

    add_index :relationships, [:source_id, :target_id, :relationship_type], unique: true, name: 'relationship_index'
  end
end
