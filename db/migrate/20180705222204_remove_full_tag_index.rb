class RemoveFullTagIndex < ActiveRecord::Migration
  def change
  	client = MediaSearch.gateway.client
    options = {
      index: CheckElasticSearchModel.get_index_name,
      type: 'tag_search',
      body: {
        script: { inline: "ctx._source.remove('full_tag')" },
        query: { bool: { must: [ { exists: { field: "full_tag" } } ] } }
      }
    }
    client.update_by_query options
  	CheckElasticSearchModel.reindex_es_data
  end
end
