class AddIndexToRelationships < ActiveRecord::Migration[4.2]
  def change
    add_index :relationships, :relationship_type
  end
end
