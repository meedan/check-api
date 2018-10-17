class TeamImportWorker
  include Sidekiq::Worker

  def perform(team_id, spreadsheet_id, user_id)
    team = Team.find_by_id(team_id)
    user = User.find_by_id(user_id)
    email = user.nil? ? nil : user.email
    team.import_spreadsheet(spreadsheet_id, email)
  end

end
