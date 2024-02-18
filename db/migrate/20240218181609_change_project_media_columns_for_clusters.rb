class ChangeProjectMediaColumnsForClusters < ActiveRecord::Migration[6.1]
  def change
    remove_column :clusters, :project_medias_count
    add_reference :clusters, :project_media, index: true # Center
  end
end
