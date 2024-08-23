namespace :check do
  namespace :migrate do
    task add_team_id_to_claim_description: :environment do |_t, args|
      started = Time.now.to_i
      slugs = args.extras
      condition = {}
      if slugs.blank?
        last_team_id = Rails.cache.read('check:migrate:add_team_id_to_claim_description:team_id') || 0
      else
        last_team_id = 0
        condition = { slug: slugs }
      end
      Team.where(condition).where('id > ?', last_team_id).find_each do |team|
        puts "Processing team [#{team.slug}]"
        team.project_medias.joins(:claim_description).find_in_batches(batch_size: 2500) do |pms|
          print '.'
          ids = pms.map(&:id)
          ClaimDescription.where(project_media_id: ids).update_all(team_id: team.id)
        end
        Rails.cache.write('check:migrate:add_team_id_to_claim_description:team_id', team.id) if slugs.blank?
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end