class ConvertProjectMediaIdToAssociatedId < ActiveRecord::Migration
  def change
    rename_column :versions, :project_media_id, :associated_id
  end
end
