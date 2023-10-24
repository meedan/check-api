class UpdateRelationshipTargetIdIndex < ActiveRecord::Migration[6.1]
  def change
    remove_index :relationships, name: 'index_relationships_on_target_id'
    add_index :relationships, :target_id
    add_index :relationships, :source_id
    add_index :relationships, [:target_id, :relationship_type]
    add_index :relationships, [:source_id, :relationship_type]
  end
end
