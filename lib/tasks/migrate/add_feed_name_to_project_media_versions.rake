namespace :check do
  namespace :migrate do
    def bulk_update_versions(team_id, updates)
      table = "versions_partitions.p#{team_id}"
      values = updates.map do |raw|
        id   = ActiveRecord::Base.connection.quote(raw[:id])
        object_after  = ActiveRecord::Base.connection.quote(raw[:object_after].to_json)
        object_changes  = ActiveRecord::Base.connection.quote(raw[:object_changes].to_json)
        meta = ActiveRecord::Base.connection.quote(raw[:meta].to_json)
        "(#{id}, #{object_after}, #{object_changes}, #{meta})"
      end.join(",")

      sql = <<~SQL
        UPDATE #{table} AS v
        SET object_after = data.object_after, object_changes = data.object_changes, meta = data.meta
        FROM (VALUES #{values}) AS data(id, object_after, object_changes, meta)
        WHERE v.id = data.id::bigint;
      SQL
      ActiveRecord::Base.connection.execute(sql)
    end
    desc "Create version logs for existing ProjectMedia with imported_from_feed_id"
    task add_feed_name_to_project_media_versions: :environment do
      started = Time.now.to_i
      puts "Starting to create version logs for ProjectMedia with imported_from_feed_id."
      last_team_id = Rails.cache.read('check:migrate:add_feed_id:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        versions = []
        team.project_medias.select("project_medias.id, project_medias.imported_from_feed_id, f.name AS feed_name")
        .joins("INNER JOIN feeds f ON f.id = project_medias.imported_from_feed_id")
        .find_in_batches(batch_size: 2500) do |pms|
          # Define a hash to hold feed id and name for each item
          pm_feed = {}
          pms.each{ |pm| pm_feed[pm.id] = { id: pm.imported_from_feed_id, name: pm.feed_name } }
          v_updates = []
          Version.from_partition(team.id).where(item_type: 'ProjectMedia', event: 'create', item_id: pms.map(&:id)).find_each do |v|
            # Append feed info for existing values.
            object_after = begin JSON.parse(v.object_after) rescue {} end
            object_after.merge!({ imported_from_feed_id: pm_feed[v.item_id.to_i][:id] })
            object_changes = begin JSON.parse(v.object_changes) rescue {} end
            object_changes.merge!({imported_from_feed_id: [nil, pm_feed[v.item_id.to_i][:id]]})
            meta = begin JSON.parse(v.meta) rescue {} end
            meta.merge!({feed_name: pm_feed[v.item_id.to_i][:name]})
            v_updates << {
              id: v.id,
              object_after: object_after,
              object_changes: object_changes,
              meta: meta
            }
          end
          bulk_update_versions(team.id, v_updates) unless v_updates.blank?
        end
        puts "Created #{versions.size} version logs for Team ID #{team.id}."
        Rails.cache.write('check:migrate:add_feed_id:team_id', team.id)
      end
      puts "Finished creating version logs."
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
