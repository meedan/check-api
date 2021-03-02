namespace :check do
  desc "Set Alegre Team Bot Installation model in use for generating string similarities (usage: bundle exec rake check:set_language_model_for_alegre_team_bot_installation['4577','indian-sbert'])"
  task :set_language_model_for_alegre_team_bot_installation, [:team_id, :model_name] => [:environment] do |_t, args|
    bot = BotUser.alegre_user
    tbi = TeamBotInstallation.find_by_team_id_and_user_id args.team_id, bot.id
    tbi.set_alegre_model_in_use = args.model_name
    tbi.save!
  end
end
