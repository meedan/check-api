class AddProjectGroupIdToProjects < ActiveRecord::Migration[4.2]
  def change
    add_column :projects, :project_group_id, :integer
    add_index :projects, :project_group_id
  end
end
