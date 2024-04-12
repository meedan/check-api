class AddImportedColumnsToProjectMedias < ActiveRecord::Migration[6.1]
  def change
    add_column :project_medias, :imported_from_feed_id, :integer
    add_column :project_medias, :imported_from_project_media_id, :integer
  end
end
