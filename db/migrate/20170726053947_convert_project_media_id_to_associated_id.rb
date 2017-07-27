class ConvertProjectMediaIdToAssociatedId < ActiveRecord::Migration
  def change
    remove_index :versions, :project_media_id
    rename_column :versions, :project_media_id, :associated_id
    add_index :versions, :associated_id
  end
end
