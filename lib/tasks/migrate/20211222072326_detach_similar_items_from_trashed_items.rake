namespace :check do
  namespace :migrate do
    task detach_similar_items_from_trashed_items: :environment do
      RequestStore.store[:skip_notifications] = true
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_team_id = Rails.cache.read('check:migrate:detach_similar_items_from_trashed_items:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        trashed_items = team.project_medias.where(archived: CheckArchivedFlags::FlagCodes::TRASHED).map(&:id)
        Relationship.where(source_id: trashed_items).where('relationship_type = ?', Relationship.suggested_type.to_yaml)
        .find_in_batches(:batch_size => 2500) do |relationships|
          es_body = []
          count_mapping = {}
          target_ids = relationships.map(&:target_id)
          target_ids.each{ |tc| count_mapping[tc.to_i] = 0 }
          # delete existing relation
          Relationship.where(id: relationships.map(&:id)).delete_all
          # query sources_count
          Relationship.select('target_id, count(target_id) as c')
          .where(target_id: target_ids)
          .where('relationship_type = ? OR relationship_type = ?', Relationship.confirmed_type.to_yaml, Relationship.suggested_type.to_yaml)
          .group('target_id').each do |raw|
            count_mapping[raw.target_id.to_i] = raw.c.to_i
          end
          # update ES
          ProjectMedia.where(id: target_ids).find_each do |target|
            print '.'
            sources_count = count_mapping[target.id.to_i]
            doc_id =  Base64.encode64("ProjectMedia/#{target.id}")
            fields = { 'parent_id' => target.id, sources_count: sources_count }
            es_body << { update: { _index: index_alias, _id: doc_id, retry_on_conflict: 3, data: { doc: fields } } }
            # update source count for target
            target.update_columns(sources_count: sources_count)
          end
          client.bulk body: es_body unless es_body.blank?
        end
        # log last team id
        puts "[#{Time.now}] Done for team #{team.slug}"
        Rails.cache.write('check:migrate:detach_similar_items_from_trashed_items:team_id', team.id)
      end
      RequestStore.store[:skip_notifications] = false
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
