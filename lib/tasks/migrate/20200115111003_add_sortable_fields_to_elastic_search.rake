namespace :check do
  namespace :migrate do
    task add_sortable_fields_to_elastic_search: :environment do
      index_alias = CheckElasticSearchModel.get_index_alias
      client = MediaSearch.gateway.client
      options = {
        index: index_alias,
        type: 'media_search',
        body: {
          media_search: {
            properties: {
              requests_count: { type: 'integer' },
              linked_items_count: { type: 'integer' },
              last_seen: { type: 'integer' }
            }
          }
        }
      }
      client.indices.put_mapping options
      ProjectMedia.find_in_batches(:batch_size => 5000) do |pms|
        es_body = []
        pms.each do |pm|
          doc_id = pm.get_es_doc_id(pm)
          fields = { 'requests_count' => pm.requests_count.to_i, 'linked_items_count' => pm.linked_items_count.to_i, 'last_seen' => pm.last_seen.to_i }
          es_body << { update: { _index: index_alias, _type: 'media_search', _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
    end
  end
end
