namespace :check do
  namespace :migrate do
    task update_cached_fields: :environment do
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
          puts "[#{Time.now}] Processing item #{pm_counter}/#{pm_count} from team #{team_counter}/#{team_count}: ##{pm.id}"
          pm.list_columns_values
        end
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
