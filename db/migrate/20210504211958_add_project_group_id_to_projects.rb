class AddProjectGroupIdToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :project_group_id, :integer
    add_index :projects, :project_group_id
  end
end
