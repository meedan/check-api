namespace :check do
  desc "Create version logs for existing ProjectMedia with imported_from_feed_id"
  task create_project_media_versions: :environment do
    puts "Starting to create version logs for ProjectMedia with imported_from_feed_id."
    last_team_id = Rails.cache.read('check:migrate:add_feed_id:team_id') || 0
    Team.where('id > ?', last_team_id).find_each do |team|
      versions = []
      team.project_medias
        .where.not(imported_from_feed_id: nil)
        .select("project_medias.id, project_medias.imported_from_feed_id, f.name AS feed_name")
        .joins("INNER JOIN feeds f ON f.id = project_medias.imported_from_feed_id")
        .find_in_batches(batch_size: 2500) do |pms|
        pms.each do |pm|
          object_after = {
            imported_from_feed_id: pm.imported_from_feed_id
          }.to_json

          object_changes = {
            imported_from_feed_id: [nil, pm.imported_from_feed_id]
          }.to_json

          meta = { feed_name: pm.feed_name }.to_json

          versions = []
          Versions = Version.from_partition(team.id)
          .where(item_type: 'ProjectMedia', item_id: pms.map(&:id), event: 'create')
          .each do |v|
            v.object_changes = object_changes
            v.object = object_after
            v.meta = meta
            versions << v
          end
      end
      Version.upsert_all(versions)
      puts "Created #{versions.size} version logs for Team ID #{team.id}."
      Rails.cache.write('check:migrate:add_feed_id:team_id', team.id)
    end
    puts "Finished creating version logs."
  end
end
