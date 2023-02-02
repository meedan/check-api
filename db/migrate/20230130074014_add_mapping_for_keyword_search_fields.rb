class AddMappingForKeywordSearchFields < ActiveRecord::Migration[5.2]
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          claim_description_context: { type: 'text', analyzer: 'check' },
          fact_check_url: { type: 'text', analyzer: 'check' },
          source_name: { type: 'text', analyzer: 'check' },
          requests: {
            type: 'nested',
            properties: {
              id: { type: 'integer'},
              username: { type: 'text', analyzer: 'check'},
              identifier: { type: 'text', analyzer: 'check'},
              content: { type: 'text', analyzer: 'check'},
            }
          },
        }
      }
    }
    client.indices.put_mapping options
  end
end
