class AddMappingForKeywordSearch < ActiveRecord::Migration[4.2]
  def change
    started = Time.now.to_i
    index_alias = CheckElasticSearchModel.get_index_alias
    client = $repository.client
    options = {
      index: index_alias,
      body: {
        properties: {
          task_responses: {
            type: 'nested',
            properties: {
              fieldset: { type: 'text'},
              field_type: { type: 'text'}
            }
          }
        }
      }
    }
    client.indices.put_mapping options
    minutes = ((Time.now.to_i - started) / 60).to_i
    puts "[#{Time.now}] Done in #{minutes} minutes."
  end
end
