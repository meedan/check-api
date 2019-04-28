namespace :check do
  namespace :migrate do
    task add_missing_language_annotations: :environment do
      RequestStore.store[:skip_notifications] = true
      puts "[#{Time.now}] Adding missing language annotations"
      teams = TeamBotInstallation.joins(:team_bot).where("identifier=?", "alegre").collect{|t| t.team_id}
      pms = ProjectMedia.joins(:project).where("team_id IN (?) AND NOT EXISTS (SELECT * FROM annotations WHERE annotated_id=project_medias.id AND annotation_type=?)", teams, "language")
      puts "[#{Time.now}] Updating #{pms.count} media in #{teams.count} teams..."
      bot = Bot::Alegre.default
      i = 0
      n = pms.count
      pms.find_each do |pm|
        i += 1
        bot.get_language(pm)
        print "#{i}/#{n}\r"
        $stdout.flush
      end
      puts "[#{Time.now}] Done!"
      RequestStore.store[:skip_notifications] = false
    end
  end
end
