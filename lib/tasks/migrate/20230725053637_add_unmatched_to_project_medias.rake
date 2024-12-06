namespace :check do
  namespace :migrate do
    task add_unmatched_to_project_media: :environment do
      started = Time.now.to_i
      last_team_id = Rails.cache.read('check:migrate:add_unmatched_to_project_media:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        print '.'
        # Get rejected and detach items from version table
        Version.from_partition(team.id).where(event_type: 'destroy_relationship')
        .where("object LIKE '%confirmed_sibling%confirmed_sibling%' OR object LIKE '%suggested_sibling%suggested_sibling%'")
        .find_in_batches(:batch_size => 1000) do |versions|
          source_ids = []
          target_ids = []
          versions.each do |v|
            object = JSON.parse(v.object)
            source_ids << object['source_id']
            target_ids << object['target_id']
          end
          source_ids = source_ids.uniq.compact
          target_ids = target_ids.uniq.compact
          all_items = source_ids.concat(target_ids).uniq
          # Get re-matched items (suggested or confirmed)
          relationships = Relationship.where('source_id IN (?) OR target_id IN (?)', all_items, all_items)
          .where('relationship_type = ? OR relationship_type = ?', Relationship.suggested_type.to_yaml, Relationship.confirmed_type.to_yaml)
          s_ids = relationships.map(&:source_id).uniq
          t_ids = relationships.map(&:target_id).uniq
          all_items_matched = s_ids.concat(t_ids).uniq
          # remove re-matched items to get the right list
          unmatched_ids = all_items - all_items_matched
          unless unmatched_ids.blank?
            print '.'
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

    # bundle exec rails check:migrate:fix_unmatched_list
    task fix_unmatched_list: :environment do |_t, args|
      started = Time.now.to_i
      slug = args.extras.last
      team_condition = {}
      if slug.blank?
        last_team_id = Rails.cache.read('check:migrate:fix_unmatched_list:team_id') || 0
      else
        last_team_id = 0
        team_condition = { slug: slug }
      end
      Team.where('id > ?', last_team_id).where(team_condition).find_each do |team|
        puts "Processing team #{team.slug} .... \n"
        unmatched_ids = team.project_medias.where(unmatched: 1).map(&:id)
        # Get re-matched items (suggested or confirmed)
        relationships = Relationship.where('source_id IN (?) OR target_id IN (?)', unmatched_ids, unmatched_ids)
        .where('relationship_type = ? OR relationship_type = ?', Relationship.suggested_type.to_yaml, Relationship.confirmed_type.to_yaml)
        s_ids = relationships.map(&:source_id).uniq
        t_ids = relationships.map(&:target_id).uniq
        matched_ids = s_ids.concat(t_ids).uniq
        unless matched_ids.blank?
          index_alias = CheckElasticSearchModel.get_index_alias
          ProjectMedia.where(id: matched_ids).find_in_batches(:batch_size => 500) do |pms|
            print '.'
            pm_ids = pms.map(&:id)
            # Update PG
            ProjectMedia.where(id: pm_ids).update_all(unmatched: 0)
            # Update ES
            options = {
              index: index_alias,
              conflicts: 'proceed',
              body: {
                script: { source: "ctx._source.unmatched = params.unmatched", params: { unmatched: 0 } },
                query: { terms: { annotated_id: pm_ids } }
              }
            }
            $repository.client.update_by_query options
          end
        end
        Rails.cache.write('check:migrate:fix_unmatched_list:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end