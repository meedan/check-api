class ConvertPaperTrailIdToString < ActiveRecord::Migration[4.2]
  def change
    change_column :versions, :item_id, :string
    remove_index :versions, [:item_type, :item_id]
    add_index :versions, [:item_type, :item_id]
  end
end
