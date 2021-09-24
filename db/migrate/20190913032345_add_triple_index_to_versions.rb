class AddTripleIndexToVersions < ActiveRecord::Migration[4.2]
  def change
    add_index :versions, [:item_type, :item_id, :whodunnit]
  end
end
