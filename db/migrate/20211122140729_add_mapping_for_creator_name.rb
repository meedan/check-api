class AddMappingForCreatorName < ActiveRecord::Migration[5.2]
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          creator_name: {
            type: 'keyword',
            fields: { raw: { type: 'text', analyzer: 'check' } },
          }
        }
      }
    }
    client.indices.put_mapping options
  end
end
