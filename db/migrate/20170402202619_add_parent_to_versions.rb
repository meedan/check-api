class AddParentToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :project_media_id, :integer
    add_index :versions, :project_media_id
  end
end
