namespace :check do
  namespace :migrate do
    task add_sortable_field_share_count_to_elastic_search: :environment do
      index_alias = CheckElasticSearchModel.get_index_alias
      client = MediaSearch.gateway.client
      ProjectMedia.find_in_batches(:batch_size => 5000) do |pms|
        es_body = []
        pms.each do |pm|
          doc_id = pm.get_es_doc_id(pm)
          fields = { 'share_count' => pm.share_count.to_i }
          es_body << { update: { _index: index_alias, _type: 'media_search', _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
    end
  end
end
