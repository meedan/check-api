class CreateClusters < ActiveRecord::Migration[5.2]
  def change
    create_table :clusters do |t|
      t.integer :project_medias_count, default: 0 # Number of items in the cluster
      t.integer :project_media_id, foreign_key: true # The "center" of this cluster
      t.timestamps
    end
    add_index :clusters, :project_media_id, unique: true
  end
end
