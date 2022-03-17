namespace :check do
  namespace :migrate do
    # bundle exec rails check:migrate:recalculate_project_media_cached_field[field]
    task recalculate_project_media_cached_field: :environment do |_t, args|
      started = Time.now.to_i
      field_name = args.extras.last
      raise "You must set field name as args for rake task Aborting." if field_name.blank?
      last_team_id = Rails.cache.read('check:migrate:recalculate_project_media_cached_field:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        team.project_medias.find_in_batches(:batch_size => 2500) do |pms|
          pms.each do |pm|
            print '.'
            pm.send(field_name, true)
          end
        end
        Rails.cache.write('check:migrate:recalculate_project_media_cached_field:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
