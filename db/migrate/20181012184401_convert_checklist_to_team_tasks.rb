class ConvertChecklistToTeamTasks < ActiveRecord::Migration[4.2]
  def change
    Team.all.each do |team|
      next unless team.get_checklist.is_a?(Array)
      team.get_checklist.each do |task|
        task = task.with_indifferent_access
        task['task_type'] = task['type']
        task['project_ids'] = task['projects']
        task['team_id'] = team.id
        ['type', :type, 'projects', :projects].each{ |key| task.delete(key) }
        tt = TeamTask.new
        task.each do |k, v|
          tt.send("#{k}=", v)
        end
        tt.save!
      end
    end
  end
end
