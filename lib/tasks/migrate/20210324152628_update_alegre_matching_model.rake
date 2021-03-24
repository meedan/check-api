namespace :check do
  namespace :migrate do
    desc "Sets the indexing model for alegre bot similarity lookups. Example: bundle exec rake check:migrate:update_algre_matching_model['team-slug',last-project-media-id]"
    task :update_algre_matching_model, [:slugs, :last] => :environment do |_task, args|
      indian_teams = Team.where(slug: args[:slugs].split(",")).collect(&:id)
      BotUser.alegre_user.team_bot_installations.find_each do |tb|
        if indian_teams.include?(tb.team_id)
          tb.set_alegre_matching_model_in_use = Bot::Alegre::INDIAN_MODEL
        else
          tb.set_alegre_matching_model_in_use = Bot::Alegre.default_model
        end
        tb.save!
      end
    end
  end
end
