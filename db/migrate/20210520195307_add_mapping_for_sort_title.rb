class AddMappingForSortTitle < ActiveRecord::Migration[4.2]
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          sort_title: {
            type: 'keyword',
          }
        }
      }
    }
    client.indices.put_mapping options
  end
end
