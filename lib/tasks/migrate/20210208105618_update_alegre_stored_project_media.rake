namespace :check do
  namespace :migrate do
    task update_alegre_stored_project_media: :environment do |_t, args|
      last_id = args.extras.last.to_i rescue 0
      BotUser.alegre_user.team_bot_installations.collect(&:team).each do |team|
        ProjectMedia.where(team_id: team.id).where("id > ? ", last_id).where("project_medias.created_at > ?", Time.parse("2020-01-01")).order('id ASC').joins("INNER JOIN annotations a ON a.annotated_type = 'ProjectMedia' AND a.annotated_id = project_medias.id INNER JOIN dynamic_annotation_fields daf ON daf.annotation_id = a.id").where('daf.annotation_type' => 'verification_status', 'daf.field_name' => ['title', 'content']).find_each do |pm|
          Bot::Alegre.send_title_to_similarity_index(pm) if !pm.title.to_s.empty?
          Bot::Alegre.send_description_to_similarity_index(pm) if !pm.description.to_s.empty?
          puts pm.id
        end
      end
    end
  end
end