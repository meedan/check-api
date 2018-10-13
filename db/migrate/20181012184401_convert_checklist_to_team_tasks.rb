class ConvertChecklistToTeamTasks < ActiveRecord::Migration
  def change
    Team.all.each do |team|
      next unless team.get_checklist.is_a?(Array)
      team.get_checklist.each do |task|
        TeamTask.create!(task.merge({ team_id: team.id }))
      end
    end
  end
end
