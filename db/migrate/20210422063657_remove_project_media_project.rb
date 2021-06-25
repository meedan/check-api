class RemoveProjectMediaProject < ActiveRecord::Migration[4.2]
  def change
  	drop_table(:project_media_projects) if table_exists?(:project_media_projects)
  end
end
