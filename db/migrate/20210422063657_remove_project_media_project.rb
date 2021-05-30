class RemoveProjectMediaProject < ActiveRecord::Migration
  def change
  	drop_table(:project_media_projects) if table_exists?(:project_media_projects)
  end
end
