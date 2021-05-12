namespace :check do
  namespace :migrate do
    desc "Forces re-index of ProjectMedias associated with a set of team_ids and optionally a start position for ProjectMedia IDs. Example: bundle exec rake check:migrate:reindex_alegre_text_project_medias['team-slug',last-project-media-id,model-name]"
    task :reindex_alegre_text_project_medias, [:slugs, :last, :model_name] => :environment do |_task, args|
      started = Time.now.to_i
      team_ids = BotUser.alegre_user.team_bot_installations.map(&:team_id).uniq.sort
      if args[:slugs]
        team_ids = Team.where(slug: args[:slugs].split(',')).map(&:id)
      end
      i = 0
      last = args[:last].to_i
      model_name = args[:model_name]
      total = ProjectMedia.where(team_id: team_ids).where('created_at > ?', Time.parse('2020-01-01')).where('id > ?', last).count
      ProjectMedia.where(team_id: team_ids).where('created_at > ?', Time.parse('2020-01-01')).where('id > ?', last).order('id ASC').find_each do |pm|
        i += 1
        if pm.is_text?
          threads = []
          klass = Bot::Alegre
          ['analysis_title', 'analysis_description', 'original_title', 'original_description'].each do |field|
            threads << Thread.new do
              text = pm.send(field).to_s
              unless text.blank?
                doc_id = klass.item_doc_id(pm, field)
                klass.send_to_text_similarity_index(pm, field, text, doc_id, model_name)
              end
            end
          end
          threads.map(&:join)
          puts "[#{Time.now}] (#{i}/#{total}) Done for project media with ID #{pm.id}"
        else
          puts "[#{Time.now}] (#{i}/#{total}) Skipping non-text project media with ID #{pm.id}"
        end
      end
      minutes = (Time.now.to_i - started) / 60
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
