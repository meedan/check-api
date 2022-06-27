namespace :check do
  namespace :migrate do
    task clear_item_cached_fields: :environment do
      started = Time.now.to_i
      interval = CheckConfig.get('cache_interval', 30).to_i
      cache_date = Time.now - interval.days
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:clear_item_cached_fields:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        team.project_medias.where('updated_at < ?', cache_date)
        .find_in_batches(:batch_size => 2500) do |pms|
          print '.'
          pms.map(&:id).each{ |id| Rails.cache.delete_matched("check_cached_field:ProjectMedia:#{id}:*") }
        end
        # log last team id
        Rails.cache.write('check:migrate:clear_item_cached_fields:team_id', team.id, expires_in: 30.days)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end