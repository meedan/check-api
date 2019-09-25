class TeamDeletionWorker
  include Sidekiq::Worker
  include ErrorNotification

  def perform(team_id, user_id)
    team = Team.find_by_id(team_id)
    return if team.nil?
    begin
      team.destroy!
    rescue StandardError => e
      Team.notify_error(e, { team_id: team_id, user_id: user_id }, RequestStore[:request] )
    end
  end

end
