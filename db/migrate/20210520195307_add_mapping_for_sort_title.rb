class AddMappingForSortTitle < ActiveRecord::Migration
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          sort_title: {
            type: 'keyword',
            normalizer: 'keyword_lowercase',
          }
        }
      }
    }
    client.indices.put_mapping options
  end
end
