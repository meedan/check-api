class MigratePendingStatus < ActiveRecord::Migration
  def change
    if CONFIG['app_name'] === 'Check'
      url = "http://#{CONFIG['elasticsearch_host']}:#{CONFIG['elasticsearch_port']}"
      client = Elasticsearch::Client.new url: url
      options = {
        index: CheckElasticSearchModel.get_index_name,
        type: 'media_search',
        body: {
          script: { inline: "ctx._source.status=status", lang: "groovy", params: { status: 'undetermined' } },
          query: { term: { status: { value: 'pending' } } }
        }
      }
      client.update_by_query options
    end
  end
end
