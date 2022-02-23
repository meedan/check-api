class AddMappingForClusterFields < ActiveRecord::Migration[5.2]
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          cluster_first_item_at: {
            type: 'long'
          },
          cluster_last_item_at: {
            type: 'long'
          },
          cluster_published_reports_count: {
            type: 'long'
          },
          cluster_requests_count: {
            type: 'long'
          },
        }
      }
    }
    client.indices.put_mapping options
  end
end
