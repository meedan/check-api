class AddElasticSearchMappingForSearchFilters < ActiveRecord::Migration
  def change
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
          properties: {
            task_responses: {
              type: 'nested',
              properties: {
                id: { type: 'integer'},
                team_task_id: { type: 'integer'},
                fieldset: { type: 'text' },
                field_name: { type: 'text' },
                value: { type: 'text', analyzer: 'keyword'}
              }
            }
          }
      }
    }
    client.indices.put_mapping options
  end
end
