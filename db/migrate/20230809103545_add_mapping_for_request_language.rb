class AddMappingForRequestLanguage < ActiveRecord::Migration[6.1]
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          requests: {
            type: 'nested',
            properties: {
              language: { type: 'keyword', normalizer: 'check' },
            }
          },
        }
      }
    }
    client.indices.put_mapping options
  end
end
