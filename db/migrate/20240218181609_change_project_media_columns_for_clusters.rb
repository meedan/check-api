class ChangeProjectMediaColumnsForClusters < ActiveRecord::Migration[6.1]
  def change
    remove_column :clusters, :project_medias_count
  end
end
