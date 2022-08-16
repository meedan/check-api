namespace :check do
  namespace :migrate do
    task add_language_to_fact_check: :environment do
      started = Time.now.to_i
      # Get latest team id
      last_team_id = Rails.cache.read('check:migrate:add_language_to_fact_check:team_id') || 0
      Team.where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        language = team.default_language || 'en'
        team.project_medias.select('fc.*')
        .joins("INNER JOIN claim_descriptions cd ON project_medias.id = cd.project_media_id")
        .joins("INNER JOIN fact_checks fc ON cd.id = fc.claim_description_id")
        .find_in_batches(:batch_size => 2500) do |items|
          ids = []
          items.each{ |i| ids << i['id'] }
          puts "ids are :: #{ids.inspect}"
          FactCheck.where(id: ids).update_all(language: language)
        end
        # log last team id
        Rails.cache.write('check:migrate:add_language_to_fact_check:team_id', team.id)
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end