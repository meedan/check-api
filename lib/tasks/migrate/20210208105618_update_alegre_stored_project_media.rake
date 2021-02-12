namespace :check do
  namespace :migrate do
    task update_alegre_stored_project_media: :environment do |_t, args|
      last_id = args.extras.last.to_i rescue 0
      t = Time.now
      running_bucket = []
      timers = []
      BotUser.alegre_user.team_bot_installations.collect(&:team).each do |team|
        ProjectMedia.where(team_id: team.id).where("project_medias.id > ? ", last_id).where("project_medias.created_at > ?", Time.parse("2020-01-01")).order('id ASC').joins("INNER JOIN annotations a ON a.annotated_type = 'ProjectMedia' AND a.annotated_id = project_medias.id INNER JOIN dynamic_annotation_fields daf ON daf.annotation_id = a.id").where('daf.annotation_type' => 'verification_status', 'daf.field_name' => ['title', 'content']).find_each do |pm|
          tz = Time.now
          running_bucket << Bot::Alegre.send_to_text_similarity_index_package(pm, 'original_title', pm.title, Bot::Alegre.item_doc_id(pm, 'original_title')) if !pm.title.to_s.empty?
          running_bucket << Bot::Alegre.send_to_text_similarity_index_package(pm, 'original_description', pm.description, Bot::Alegre.item_doc_id(pm, 'original_description')) if !pm.description.to_s.empty?
          running_bucket << Bot::Alegre.send_to_text_similarity_index_package(pm, 'analysis_title', pm.title, Bot::Alegre.item_doc_id(pm, 'analysis_title')) if !pm.has_analysis_title?
          running_bucket << Bot::Alegre.send_to_text_similarity_index_package(pm, 'analysis_description', pm.description, Bot::Alegre.item_doc_id(pm, 'analysis_description')) if !pm.has_analysis_description?
          puts pm.id
          if running_bucket.length > 50
            # Bot::Alegre.request_api('post', '/text/bulk_similarity', {documents: running_bucket})
            running_bucket = []
          end
          ttz = Time.now
          timers << (ttz - tz)
        end
      end
      tt = Time.now
      puts tt-t
    end
  end
end