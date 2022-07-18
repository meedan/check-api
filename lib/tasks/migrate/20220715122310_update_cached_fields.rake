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

      SLUG_GROUPS = [].each_slice(5).to_a

      QUARTER = 1
      MONTH = QUARTER * 3 
      SLUGS = SLUG_GROUPS[0]

      started = Time.now.to_i
      team_ids = Team.where(slug: SLUGS).map(&:id)
      query = ProjectMedia.where(team_id: team_ids).where('archived != 1').where(created_at: Time.now.ago(MONTH.months)..Time.now.ago((MONTH - 3).months))
      pm_count = query.count
      pm_counter = 0
      query.find_each do |pm|
        pm_counter += 1
        failed = false
        begin
          CACHED_FIELDS.each { |field| pm.send(field) } # Just cache if it's not cached yet
          pm.list_columns_values
        rescue Exception => e
          failed = e.message
        end
        puts "[#{Time.now}] Processed item #{pm_counter}/#{pm_count}: ##{pm.id} (#{failed ? 'failed with ' + e.message : 'success'})"
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
