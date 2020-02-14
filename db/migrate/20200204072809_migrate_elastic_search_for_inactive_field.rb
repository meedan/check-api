class MigrateElasticSearchForInactiveField < ActiveRecord::Migration
  def change
  	ids = ProjectMedia.where(inactive: true).map(&:id)
  	client = MediaSearch.gateway.client
    options = {
      index: CheckElasticSearchModel.get_index_alias,
      type: 'media_search',
      conflicts: 'proceed'
    }
    # reset items with inactive = 1 and not exists in ids 
    body = {
      script: { source: "ctx._source.inactive = params.inactive", params: { inactive: 0 } },
      query: { bool: { must: [ { term: { inactive: { value: 1 } } } ], must_not: [ { terms: { annotated_id: ids } } ] } }
    }
    options[:body] = body
    client.update_by_query options
    # sync inactive betwwn ES and PG
    sleep 5
    body = {
      script: { source: "ctx._source.inactive = params.inactive", params: { inactive: 1 } },
      query: { terms: { annotated_id: ids } }
    }
    options[:body] = body
    client.update_by_query options
  end
end
