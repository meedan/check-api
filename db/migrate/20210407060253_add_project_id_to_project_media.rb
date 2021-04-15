class AddProjectIdToProjectMedia < ActiveRecord::Migration
  def change
    add_column :project_medias, :project_id, :integer
    add_index :project_medias, :project_id
  end
end
