class MigratePendingStatus < ActiveRecord::Migration
  def change
    if CheckConfig.get('app_name') === 'Check' && !defined?(Status).nil?
      client = $repository.client
      options = {
        index: CheckElasticSearchModel.get_index_name,
        body: {
          script: { source: "ctx._source.status = params.status", params: { status: 'undetermined' } },
          query: { term: { status: { value: 'pending' } } }
        }
      }
      client.update_by_query options
    end
  end
end
