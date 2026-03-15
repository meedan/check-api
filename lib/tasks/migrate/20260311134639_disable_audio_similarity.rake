namespace :check do
  namespace :migrate do
    # bundle exec rails check:migrate:disable_audio_similarity
    task disable_audio_similarity: :environment do
      alegre = BotUser.alegre_user
      TeamBotInstallation.where(user_id: alegre.id).where('settings IS NOT NULL').find_each do |tbi|
         if tbi.get_audio_similarity_enabled
          print '.'
          tbi.set_audio_similarity_enabled = false
          settings = tbi.settings
          tbi.update_column(:settings, settings)
         end
      end
    end
  end
end