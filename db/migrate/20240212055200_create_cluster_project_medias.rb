class CreateClusterProjectMedias < ActiveRecord::Migration[6.1]
  def change
    create_table :cluster_project_medias do |t|
      t.references :cluster
      t.references :project_media
    end
    add_index :cluster_project_medias, :cluster_id
    add_index :cluster_project_medias, :project_media_id
    add_index :cluster_project_medias, [:cluster_id, :project_media_id], unique: true
    add_reference :clusters, :feed, index: true
  end
end
