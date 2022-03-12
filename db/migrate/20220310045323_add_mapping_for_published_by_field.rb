class AddMappingForPublishedByField < ActiveRecord::Migration[5.2]
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          published_by: {
            type: 'long'
          },
        }
      }
    }
    client.indices.put_mapping options
  end
end
