namespace :check do
  namespace :migrate do
    # Get versions count
    task get_versions_count: :environment do
      count = {}
      Team.find_each do |team|
        print '.'
        count[team.slug] = Version.from_partition(team.id).count
      end
      total = count.values.sum
      puts "Count per team: #{count.inspect}"
      puts "Total count is: #{total}"
    end
    task delete_unneeded_logs: :environment do
      started = Time.now.to_i
      data = [] 
      last_team_id = Rails.cache.read('check:migrate:delete_unneeded_logs:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Process team : #{team.slug}"
        condition = {}
        # - Account  (create/update)
        condition[:item_type] = 'Account'
        Version.from_partition(team.id).where(condition).delete_all
        # - BotResource (create/update)
        condition[:item_type] = 'BotResource'
        Version.from_partition(team.id).where(condition).delete_all
        # - Team (create/update)
        condition[:item_type] = 'Team'
        Version.from_partition(team.id).where(condition).delete_all
        # - Media (create/update)
        condition[:item_type] = 'Media'
        Version.from_partition(team.id).where(condition).delete_all
        # - Project (create/update)
        condition[:item_type] = 'Project'
        Version.from_partition(team.id).where(condition).delete_all
        # - Source (create/update)
        condition[:item_type] = 'Source'
        Version.from_partition(team.id).where(condition).delete_all
        # -Comment
        condition[:item_type] = 'Comment'
        Version.from_partition(team.id).where(condition).delete_all
        # - TiplineSubscription (create/update)
        condition[:item_type] = 'TiplineSubscription'
        Version.from_partition(team.id).where(condition).where.not(event: 'destroy').delete_all
        # - Annotations (create/update/destroy) [keep the following types -['tag', 'report_design', 'verification_status']-]
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          pm_ids = pms.map(&:id)
          Dynamic.where(annotated_type: 'ProjectMedia', annotated_id: pm_ids)
          .where.not(annotation_type: ['tag', 'verification_status', 'report_design']).find_in_batches(:batch_size => 2500) do |ds|
            print '.'
            ds_ids = ds.map(&:id)
            Version.from_partition(team.id).where(item_type: 'Dynamic', item_id: ds_ids).delete_all
          end
        end
        # - TODO
        # - Field (create/update) [keep the following field names -[language, verification_status_status] || , f.annotation_type =~ /^task_response/]-]
        Rails.cache.write('check:migrate:delete_unneeded_logs:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
    # Task to update existing logs for relationships
    task fix_relationships_log: :environment do
      started = Time.now.to_i
      alegre_id = BotUser.alegre_user&.id
      last_team_id = Rails.cache.read('check:migrate:fix_relationships_log:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team : #{team.slug}"
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          re_mapping = {}
          relationships = Relationship.where(source_id: pms.map(&:id))
          relationships.collect{ |r| re_mapping[r.id] = { source: r.source_id, target: r.target_id}}
          source_meta = {}
          ProjectMedia.select("project_medias.*, medias.type").where(id: relationships.map(&:source_id)).joins(:media).find_each do |pm|
            print '.'
            source_meta[pm.id] = {
              source: {
                title: pm.title,
                type: pm.type,
                url: "#{CheckConfig.get('checkdesk_client')}/#{team.slug}/project/#{pm.project_id}/media/#{pm.id}",
              }
            }
          end
          versions = []
          deleted_ids = []
          Version.from_partition(team.id).where(item_id: relationships.map(&:id), item_type: 'Relationship').find_each do |v|
            deleted_ids << v.id
            unless source_meta[v.associated_id].blank?
              print '.'
              meta = source_meta[v.associated_id]
              meta[:source][:by_check] = alegre_id == v.whodunnit&.to_i
              relation_log = v.dup.attributes
              relation_log.delete('id')
              relation_log['created_at'] = v.created_at
              relation_log['associated_id'] = re_mapping[v.item_id.to_i][:target]
              relation_log['meta'] = meta.to_json
              versions << relation_log
            end
          end
          # Import new ones
          ProjectMedia.bulk_import_versions(versions, team.id) if versions.size > 0
          # Delete existings vesions
          Version.from_partition(team.id).where(id: deleted_ids).delete_all if deleted_ids.size > 0
        end
        Rails.cache.write('check:migrate:fix_relationships_log:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
    # Task to fix ProjectMedias log
    task fix_project_medias_log: :environment do
      started = Time.now.to_i
      last_team_id = Rails.cache.read('check:migrate:fix_project_medias_log:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team : #{team.slug}"
        source_mapping = {}
        team.sources.collect{ |s| source_mapping[s.id] = s.name }
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          ids = pms.map(&:id)
          # handle create event logs
          versions = []
          deleted_ids = []
          Version.from_partition(team.id).where(item_id: ids, item_type: 'ProjectMedia', event_type:'create_projectmedia')
          .find_each do |v|
            print '.'
            deleted_ids << v.id
            create_log = v.dup.attributes
            create_log.delete('id')
            create_log['created_at'] = v.created_at
            create_log['associated_id'] = v.item_id.to_i
            create_log['associated_type'] = 'ProjectMedia'
            versions << create_log
            # add one for source creation
            object_changes = JSON.parse(v.object_changes)
            if object_changes.keys.include?('source_id')
              source_id = object_changes['source_id'][1]
              unless source_mapping[source_id].blank?
                source_log = v.dup.attributes
                source_log.delete('id')
                source_log['created_at'] = v.created_at
                source_log['associated_id'] = v.item_id.to_i
                source_log['associated_type'] = 'ProjectMedia'
                source_log['meta'] = { add_source: true, source_name: source_mapping[source_id] }.to_json
                versions << source_log
              end
            end
          end
          # Import new ones
          ProjectMedia.bulk_import_versions(versions, team.id) if versions.size > 0
          # Delete existings vesions
          Version.from_partition(team.id).where(id: deleted_ids).delete_all if deleted_ids.size > 0

          # Handle update events log
          versions = []
          deleted_ids = []
          Version.from_partition(team.id).where(item_id: ids, item_type: 'ProjectMedia', event_type:'update_projectmedia')
          .find_each do |v|
            print '.'
            deleted_ids << v.id
            # add meta for source change
            object_changes = JSON.parse(v.object_changes)
            if object_changes.keys.include?('source_id')
              source_id = object_changes['source_id'][1]
              unless source_mapping[source_id].blank?
                update_log = v.dup.attributes
                update_log.delete('id')
                update_log['created_at'] = v.created_at
                update_log['meta'] = { add_source: true, source_name: source_mapping[source_id] }.to_json
                versions << update_log
              end
            end
          end
          # Import new ones
          ProjectMedia.bulk_import_versions(versions, team.id) if versions.size > 0
          # Delete existings vesions
          Version.from_partition(team.id).where(id: deleted_ids).delete_all if deleted_ids.size > 0
        end
        Rails.cache.write('check:migrate:fix_project_medias_log:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end