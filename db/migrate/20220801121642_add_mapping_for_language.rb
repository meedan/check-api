class AddMappingForLanguage < ActiveRecord::Migration[5.2]
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          language: { type: 'text', analyzer: 'keyword' }
        }
      }
    }
    client.indices.put_mapping options
  end
end
