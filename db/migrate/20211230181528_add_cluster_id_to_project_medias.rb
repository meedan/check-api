class AddClusterIdToProjectMedias < ActiveRecord::Migration[5.2]
  def change
    add_column :project_medias, :cluster_id, :integer
    add_index :project_medias, :cluster_id
  end
end
