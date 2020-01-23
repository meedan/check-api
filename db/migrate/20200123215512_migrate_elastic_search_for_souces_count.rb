class MigrateElasticSearchForSoucesCount < ActiveRecord::Migration
  def change
    client = MediaSearch.gateway.client
    options = {
      index: CheckElasticSearchModel.get_index_alias,
      type: 'media_search',
      conflicts: 'proceed',
      body: {
        script: { source: "ctx._source.sources_count = params.sources_count", params: { sources_count: 0 } },
        query: { bool: { must_not: { exists: { field: "sources_count" } } } }
      }
    }
    client.update_by_query options
  end
end
