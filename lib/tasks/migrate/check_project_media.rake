namespace :check do
  desc "Create version logs for existing ProjectMedia with imported_from_feed_id"
  task create_project_media_versions: :environment do
    puts "Starting to create version logs for ProjectMedia with imported_from_feed_id."
    last_team_id = Rails.cache.read('check:migrate:add_feed_id:team_id') || 0
    Team.where('id > ?', last_team_id).find_each do |team|
      versions = []
      team.project_medias.where.not("imported_from_feed_id is NULL").find_in_batches(:batch_size => 2500) do |pms|
        pms.each do |pm|
          feed = Feed.find_by_id(pm.imported_from_feed_id)
          source = pm.source

          object_after = {
            source_id: pm.source_id,
            imported_from_feed_id: pm.imported_from_feed_id
          }.to_json

          object_changes = {
            source_id: [nil, pm.source_id],
            imported_from_feed_id: [nil, pm.imported_from_feed_id]
          }.to_json

          meta = {
            feed_name: feed&.name,
            source_name: source&.name
          }.to_json

          versions << {
              item_type: 'ProjectMedia',
              item_id: pm.id,
              event: 'create',
              whodunnit: pm.user.id,
              object: nil,
              object_changes: object_changes,
              created_at: pm.created_at,
              meta: meta,
              event_type: 'create_projectmedia',
              object_after: object_after,
              associated_id: pm.id,
              associated_type: 'ProjectMedia',
            }
          end
      end
      Version.insert_all(versions)
      puts "Created #{versions.size} version logs for Team ID #{team.id}."
      Rails.cache.write('check:migrate:add_feed_id:team_id', team.id)
    end
    puts "Finished creating version logs."
  end
end
