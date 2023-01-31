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
        }
      }
    }
    client.indices.put_mapping options
  end
end
