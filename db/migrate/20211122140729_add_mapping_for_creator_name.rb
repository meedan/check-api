class AddMappingForCreatorName < ActiveRecord::Migration[5.2]
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    # update settings with check normalizer
    client.indices.close index: index_alias, wait_for_active_shards: 0
    body = {
      analysis: {
        normalizer: {
          check: {
            type: 'custom',
            filter: ['lowercase', 'asciifolding','icu_normalizer','arabic_normalization']
          }
        }
      }
    }
    client.indices.put_settings body: body, index: index_alias
    client.indices.open index: index_alias
    # update mapping with creator_name field
    options = {
      index: index_alias,
      body: {
        properties: {
          creator_name: {
            type: 'keyword',
            normalizer: 'check',
            fields: { raw: { type: 'text', analyzer: 'check' } }
          }
        }
      }
    }
    client.indices.put_mapping options
  end
end
