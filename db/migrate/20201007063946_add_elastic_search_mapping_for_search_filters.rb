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
				        id: { type: 'text'},
				        field_name: { type: 'text' },
				        value: { type: 'text', analyzer: 'check'}
				      }
				    }
          }
      }
    }
    client.indices.put_mapping options
  end
end
