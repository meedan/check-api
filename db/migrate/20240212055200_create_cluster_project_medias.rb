class CreateClusterProjectMedias < ActiveRecord::Migration[6.1]
  def change
    create_table :cluster_project_medias do |t|
      t.references :cluster
      t.references :project_media
    end
    add_index :cluster_project_medias, [:cluster_id, :project_media_id], unique: true
    add_reference :clusters, :feed, index: true
    remove_reference :clusters, :project_media, index: true
    remove_reference :project_medias, :cluster, index: true
    # TODO: remove clusters.project_medias_count
  end
end
