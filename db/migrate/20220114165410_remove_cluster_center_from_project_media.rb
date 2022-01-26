class RemoveClusterCenterFromProjectMedia < ActiveRecord::Migration[5.2]
  def change
    remove_column :project_medias, :cluster_center
  end
end
