class DropProjectsAndProjectGroupsTables < ActiveRecord::Migration[6.1]
  def change
    drop_table :projects
    drop_table :project_groups
    remove_column :project_medias, :project_id
  end
end
