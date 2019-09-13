class AddTripleIndexToVersions < ActiveRecord::Migration
  def change
    add_index :versions, [:item_type, :item_id, :whodunnit]
  end
end
