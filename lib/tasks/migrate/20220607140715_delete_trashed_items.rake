namespace :check do
  namespace :migrate do
    task delete_trashed_items: :environment do
      started = Time.now.to_i
      # Get latest team id
      deleted_date = Time.now - 30.days
      last_team_id = Rails.cache.read('check:migrate:delete_trashed_items:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        team.project_medias.where(archived: CheckArchivedFlags::FlagCodes::TRASHED)
        .where('updated_at <= ?', deleted_date)
        .find_in_batches(:batch_size => 2500) do |pms|
          pms.each do |pm|
            print '.'
            pm.destroy!
          end
        end
        # log last team id
        Rails.cache.write('check:migrate:delete_trashed_items:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end

    task enqueue_trashed_items_for_delete_forever: :environment do
      started = Time.now.to_i
      # Get latest team id
      interval = CheckConfig.get('empty_trash_interval', 30).to_i
      updated_at = Time.now
      last_team_id = Rails.cache.read('check:migrate:enqueue_trashed_items_for_delete_forever:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        team.project_medias.where(archived: CheckArchivedFlags::FlagCodes::TRASHED)
        .find_in_batches(:batch_size => 2500) do |pms|
          print '.'
          ids = pms.map(&:id)
          ids.each{ |pm_id| ProjectMedia.delay_for(interval.days).delete_forever('trash', updated_at, pm_id) }
        end
        # log last team id
        Rails.cache.write('check:migrate:enqueue_trashed_items_for_delete_forever:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end