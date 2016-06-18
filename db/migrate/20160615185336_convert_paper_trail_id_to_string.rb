class ConvertPaperTrailIdToString < ActiveRecord::Migration
  def change
    change_column :versions, :item_id, :string
    remove_index :versions, [:item_type, :item_id]
    add_index :versions, [:item_type, :item_id]
  end
end
