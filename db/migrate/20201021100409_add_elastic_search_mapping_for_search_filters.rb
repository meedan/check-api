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
                value: { type: 'text', analyzer: 'check', fields: { raw: { type: 'text', analyzer: 'keyword' } } }
              }
            }
          }
      }
    }
    client.indices.put_mapping options
    # Initial team tasks with []
    ProjectMedia.find_in_batches(:batch_size => 2500) do |pms|
      print '.'
      ids = pms.map(&:id)
      body = {
        script: { source: "ctx._source.task_responses = params.task_responses", params: { task_responses: [] } },
        query: { terms: { annotated_id: ids } }
      }
      options[:body] = body
      client.update_by_query options
    end
  end
end
