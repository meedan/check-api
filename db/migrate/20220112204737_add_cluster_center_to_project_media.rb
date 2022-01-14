class AddClusterCenterToProjectMedia < ActiveRecord::Migration[5.2]
  def change
    add_column :project_medias, :cluster_center, :boolean, default: false
    add_index :project_medias, :cluster_center
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          cluster_center: {
            type: 'integer'
          }
        }
      }
    }
    client.indices.put_mapping options
  end
end
