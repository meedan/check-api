class AddIndexToRelationships < ActiveRecord::Migration
  def change
    add_index :relationships, :relationship_type
  end
end
