namespace :check do
  namespace :migrate do
    desc "Sets the indexing model for alegre bot similarity lookups. Example: bundle exec rake check:migrate:update_alegre_matching_model['team-slug']"
    task :update_alegre_matching_model, [:slugs, :last] => :environment do |_task, args|
      indian_teams = Team.where(slug: args[:slugs].split(",")).collect(&:id)
      BotUser.alegre_user.team_bot_installations.find_each do |tb|
        if indian_teams.include?(tb.team_id)
          tb.set_text_similarity_model = Bot::Alegre::INDIAN_MODEL
        else
          tb.set_text_similarity_model = Bot::Alegre.default_model
        end
        tb.save!
      end
    end
  end
end
