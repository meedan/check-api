namespace :check do
  desc "Set Alegre Team Bot Installation model in use for generating string similarities (usage: bundle exec rake check:set_language_model_for_alegre_team_bot_installation['4577','indian-sbert'])"
  task :set_language_model_for_alegre_team_bot_installation, [:team_id, :model_name] => [:environment] do |_t, args|
    team = Team.find(args.team_id)
    tbi = team.team_bot_installations.select{|x| x.user.login == "alegre"}.first
    tbi.set_alegre_model_in_use = args.model_name
    tbi.save!
  end
end
