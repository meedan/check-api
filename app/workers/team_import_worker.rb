class TeamImportWorker
  include Sidekiq::Worker

  def perform(team_id, spreadsheet_id, user_id)
    team = Team.find_by_id(team_id)
    team.import_spreadsheet(spreadsheet_id, user_id)
  end

end
