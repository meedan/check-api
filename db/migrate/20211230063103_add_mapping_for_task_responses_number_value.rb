class AddMappingForTaskResponsesNumberValue < ActiveRecord::Migration[5.2]
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
              numeric_value: { type: 'integer' },
            }
          }
        }
      }
    }
    client.indices.put_mapping options
  end
end
