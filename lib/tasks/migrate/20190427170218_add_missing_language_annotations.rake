namespace :check do
  namespace :migrate do
    task add_missing_language_annotations: :environment do
      RequestStore.store[:skip_notifications] = true
      puts "[#{Time.now}] Adding missing language annotations"
      teams = TeamBotInstallation.joins(:team_bot).where("identifier=?", "alegre").collect{|t| t.team_id}
      pms = ProjectMedia.joins(:project).where("team_id IN (?) AND NOT EXISTS (SELECT * FROM annotations WHERE annotated_id=project_medias.id AND annotation_type=?)", teams, "language")
      bot = Bot::Alegre.default
      i = 0
      n = pms.count
      texts = []
      puts "[#{Time.now}] Getting texts for #{n} media"
      pms.find_each do |pm|
        texts << pm.text unless pm.text.blank?
        i += 1
        print "#{i}/#{n}\r"
        $stdout.flush
      end
      uniq_texts = texts.uniq
      puts "[#{Time.now}] Getting language for #{uniq_texts.size} unique texts from #{texts.size} texts"
      langs = {}
      threads = []
      i = 0
      groups = texts.uniq.each_slice((uniq_texts.size / 20.0).ceil).to_a
      groups.each do |group|
        threads << Thread.new do
          group.each do |text|
            langs[text] = bot.get_language_from_alegre(text)
            i += 1
            print "#{i}/#{uniq_texts.size}\r"
            $stdout.flush
          end
        end
      end
      threads.map(&:join)
      puts "[#{Time.now}] Creating #{pms.count} media in #{teams.count} teams in memory first..."
      i = 0
      groups = []
      pms.find_each do |pm|
        i += 1
        lang = pm.text.blank? ? 'und' : (langs[pm.text] || bot.get_language_from_alegre(pm.text))
        annotation = Dynamic.new
        annotation.annotated = pm
        annotation.annotator = bot
        annotation.annotation_type = 'language'
        annotation.disable_es_callbacks = Rails.env.to_s == 'test'
        annotation.set_fields = { language: lang }.to_json
        groups[i % 5] ||= []
        groups[i % 5] << annotation
        print "#{i}/#{n}\r"
        $stdout.flush
      end
      puts "[#{Time.now}] Saving #{pms.count} media in #{teams.count} teams..."
      threads = []
      i = 0
      groups.each do |group|
        threads << Thread.new do
          group.each do |annotation|
            annotation.save(validate: false)
            i += 1
            print "#{i}/#{n}\r"
            $stdout.flush
          end
        end
      end
      threads.map(&:join)
      puts "[#{Time.now}] Done!"
      RequestStore.store[:skip_notifications] = false
    end
  end
end
