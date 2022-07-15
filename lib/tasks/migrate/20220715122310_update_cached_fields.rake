namespace :check do
  namespace :migrate do
    task update_cached_fields: :environment do
      CACHED_FIELDS = [
        'linked_items_count', 'suggestions_count', 'is_suggested', 'is_confirmed', 'related_count',
        'requests_count', 'demand', 'last_seen', 'description', 'title', 'status', 'share_count',
        'reaction_count', 'comment_count', 'report_status', 'tags_as_sentence', 'sources_as_sentence',
        'media_published_at', 'published_by', 'type_of_media', 'added_as_similar_by_name',
        'confirmed_as_similar_by_name', 'folder', 'show_warning_cover', 'picture',
        'team_name', 'creator_name'
      ]

      started = Time.now.to_i
      interval = CheckConfig.get('cache_interval', 30).to_i
      cache_date = Time.now - interval.days
      team_count = Team.count
      team_counter = 0
      Team.find_each do |team|
        team_counter += 1
        puts "[#{Time.now}] Processing team #{team_counter}/#{team_count}: #{team.slug}"
        query = team.project_medias.where('updated_at > ?', cache_date)
        pm_count = query.count
        pm_counter = 0
        query.find_each do |pm|
          pm_counter += 1
          failed = false
          begin
            pm.list_columns_values
            CACHED_FIELDS.each { |field| pm.send(field) } # Just cache if it's not cached yet
          rescue Exception => e
            failed = e.message
          end
          puts "[#{Time.now}] Processed item #{pm_counter}/#{pm_count} from team #{team_counter}/#{team_count}: ##{pm.id} (#{failed ? 'failed with ' + e.message : 'success'})"
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
