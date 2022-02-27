namespace :check do
  namespace :migrate do
    task fix_parent_id_and_sources_count_for_suggested_items: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      Relationship.where('relationship_type = ?', Relationship.suggested_type.to_yaml)
      .find_in_batches(:batch_size => 2500) do |items|
        # Update PG
        ids = items.map(&:target_id)
        ProjectMedia.where(id: ids).update_all(sources_count: 0)
        # Update ES
        es_body = []
        items.each do |item|
          print '.'
          doc_id =  Base64.encode64("ProjectMedia/#{item.target_id}")
          fields = { 'parent_id' => item.target_id, 'sources_count' => 0 }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      minutes = (Time.now.to_i - started) / 60
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end