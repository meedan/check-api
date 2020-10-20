class UpdateSmoochBotInstallations < ActiveRecord::Migration
  def change
    # Iterate through Smooch Bot installations in order to store bot resources
    current_user = User.current
    current_team = Team.current
    User.current = bot = BotUser.where(login: 'smooch').last
    bot.team_bot_installations.each do |tbi|
      puts "Updating Smooch Bot for team #{tbi.team.name}..."
      tbi = tbi.becomes(TeamBotInstallation)
      Team.current = tbi.team
      begin
        Bot::Smooch.save_resources(tbi.team_id, tbi.settings)
      rescue
        puts "Couldn't save resources for team #{tbi.team.name}"
      end
    end
    Team.current = current_team
    User.current = current_user
  end
end
