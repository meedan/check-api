class AddProjectIdToProjectMedia < ActiveRecord::Migration[4.2]
  def change
    add_column :project_medias, :project_id, :integer
    add_index :project_medias, :project_id
  end
end
