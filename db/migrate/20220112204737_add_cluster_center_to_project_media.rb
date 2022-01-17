class AddClusterCenterToProjectMedia < ActiveRecord::Migration[5.2]
  def change
    add_column :project_medias, :cluster_center, :boolean, default: false
    add_index :project_medias, :cluster_center
  end
end
