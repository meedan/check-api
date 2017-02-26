class AddIndex < ActiveRecord::Migration
  def change
    add_index :versions, :item_id
    add_index :versions, :item_type
    add_index :annotations, :annotated_type
  end
end
