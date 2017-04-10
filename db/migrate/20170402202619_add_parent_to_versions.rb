class AddParentToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :project_media_id, :integer
    add_index :versions, :project_media_id
  end
end
