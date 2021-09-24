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
          },
          task_comments: {
            type: 'nested',
            properties: {
              id: { type: 'text'},
              team_task_id: { type: 'integer'},
              text: { type: 'text', analyzer: 'check'}
            }
          }
        }
      }
    }
    client.indices.put_mapping options
    # Initial task comments with []
    ProjectMedia.find_in_batches(:batch_size => 2500) do |pms|
      print '.'
      ids = pms.map(&:id)
      body = {
        script: { source: "ctx._source.task_comments = params.task_comments", params: { task_comments: [] } },
        query: { terms: { annotated_id: ids } }
      }
      options[:body] = body
      client.update_by_query options
    end
    minutes = ((Time.now.to_i - started) / 60).to_i
    puts "[#{Time.now}] Done in #{minutes} minutes."
  end
end
