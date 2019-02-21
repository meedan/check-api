class TeamDeletionWorker
  include Sidekiq::Worker

  def perform(team_id, user_id)
    team = Team.find_by_id(team_id)
    return if team.nil?
    begin
      team.destroy!
    rescue StandardError => e
      Airbrake.notify(e, parameters: { team_id: team_id, user_id: user_id })
    end
  end

end
