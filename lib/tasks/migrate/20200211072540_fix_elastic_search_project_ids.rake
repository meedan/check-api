namespace :check do
  namespace :migrate do
    task fix_elastic_search_project_ids: :environment do
      index_alias = CheckElasticSearchModel.get_index_alias
      client = MediaSearch.gateway.client
      ProjectMedia.find_in_batches(:batch_size => 5000) do |pms|
        es_body = []
        pms.each do |pm|
        	print "."
          doc_id = pm.get_es_doc_id(pm)
          fields = { 'project_id' => pm.project_ids }
          es_body << { update: { _index: index_alias, _type: 'media_search', _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
    end
  end
end
