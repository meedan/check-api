class ReindexEsForAssociatedType < ActiveRecord::Migration
  def change
    CheckElasticSearchModel.reindex_es_data
    sleep 2
    # set associated type for project media
    medias = MediaSearch.search(query: { match: { annotated_type: 'projectmedia' } }, size: 10000)
    medias.each do |m|
      pm = ProjectMedia.where(id: m.id).last
      m.update associated_type: pm.media.type unless pm.nil?
    end
    sleep 2
    # set associated type for project source
    url = "http://#{CONFIG['elasticsearch_host']}:#{CONFIG['elasticsearch_port']}"
    client = Elasticsearch::Client.new url: url
    options = {
      index: CheckElasticSearchModel.get_index_name,
      type: 'media_search',
      body: {
        script: { inline: "ctx._source.associated_type=associated_type", lang: "groovy", params: { associated_type: 'source' } },
        query: { term: { annotated_type: { value: 'projectsource' } } }
      }
    }
    client.update_by_query options
  end
end
