namespace :check do
  namespace :migrate do
    task add_unmatched_to_project_media: :environment do
      started = Time.now.to_i
      last_team_id = Rails.cache.read('check:migrate:add_unmatched_to_project_media:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        # Get rejected and detach items from version table
        Version.from_partition(team.id).where(event_type: 'destroy_relationship')
        .where("object LIKE '%confirmed_sibling%confirmed_sibling%' OR object LIKE '%suggested_sibling%suggested_sibling%'")
        .find_in_batches(:batch_size => 1000) do |versions|
          pm_ids = versions.map(&:associated_id).uniq
          # Get re-matched items (suggested or confirmed)
          target_ids = Relationship.where(target_id: pm_ids)
          .where('relationship_type = ? OR relationship_type = ?', Relationship.suggested_type.to_yaml, Relationship.confirmed_type.to_yaml)
          .map(&:target_id)
          # remove re-matched items to get the right list
          unmatched_ids = pm_ids - target_ids
          unless unmatched_ids.blank?
            # Update PG
            ProjectMedia.where(id: unmatched_ids).update_all(unmatched: 1)
            # Update ES
            options = {
              index: CheckElasticSearchModel.get_index_alias,
              conflicts: 'proceed',
              body: {
                script: { source: "ctx._source.unmatched = params.unmatched", params: { unmatched: 1 } },
                query: { terms: { annotated_id: unmatched_ids } }
              }
            }
            $repository.client.update_by_query options
          end
        end
        Rails.cache.write('check:migrate:add_unmatched_to_project_media:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end