class UpdateClusterIndex < ActiveRecord::Migration[6.1]
  def change
    remove_index :clusters, name: 'index_clusters_on_project_media_id' # It should not be unique anymore
    add_index :clusters, :project_media_id
  end
end
