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

    task fix_parent_id_and_sources_count_for_confirmed_items: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      Relationship.where('relationship_type = ?', Relationship.confirmed_type.to_yaml)
      .find_in_batches(:batch_size => 2500) do |items|
        ids = items.map(&:target_id)
        target_count = Relationship.where(target_id: ids)
        .where('relationship_type = ?', Relationship.confirmed_type.to_yaml).group(:target_id).count
        # Update PG with sources_count value
        updated_items = []
        target_count.each do |k, v|
          pg_item = ProjectMedia.new
          pg_item.id = k
          pg_item.sources_count = v
          updated_items << pg_item
        end
        # Import items with existing ids to make update
        imported = ProjectMedia.import(updated_items, recursive: false, validate: false, on_duplicate_key_update: [:sources_count])
        # Update ES
        es_body = []
        items.each do |item|
          print '.'
          target_id = item.target_id
          doc_id =  Base64.encode64("ProjectMedia/#{target_id}")
          fields = { 'parent_id' => item.source_id, 'sources_count' => target_count[target_id] }
          es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
        end
        client.bulk body: es_body unless es_body.blank?
      end
      minutes = (Time.now.to_i - started) / 60
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end