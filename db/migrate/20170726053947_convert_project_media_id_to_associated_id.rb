class ConvertProjectMediaIdToAssociatedId < ActiveRecord::Migration[4.2]
  def change
    remove_index :versions, :project_media_id
    rename_column :versions, :project_media_id, :associated_id
    add_index :versions, :associated_id

    PaperTrail::Version.reset_column_information
  end
end
