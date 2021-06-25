class SetAssignmentsProgressCache < ActiveRecord::Migration[4.2]
  def change
    uids = Assignment.joins("INNER JOIN annotations a ON a.id = assignments.assigned_id AND a.annotation_type = 'task'").where(assigned_type: 'Annotation').distinct('assignments.user_id').select('assignments.user_id AS uid').map(&:uid)
    users = User.where(id: uids)
    n = users.count
    puts "About to migrate #{n} users assigned to tasks"
    
    i = 0
    users.each do |user|
      i += 1
      puts "[#{Time.now}] (#{i}/#{n}) Setting progress cache for assignments of user with id #{user.id}"

      teams = Team.where(id: Assignment.where(user_id: user.id, assigned_type: 'Annotation').joins("INNER JOIN annotations a ON a.annotation_type = 'task' AND a.id = assignments.assigned_id INNER JOIN project_medias pm ON pm.id = a.annotated_id INNER JOIN projects p ON p.id = pm.project_id").distinct('p.team_id').select('p.team_id AS team_id').map(&:team_id))
      teams.each do |team|
        tu = TeamUser.where(team_id: team.id, user_id: user.id).last
        TeamUser.set_assignments_progress(user.id, team.id) unless tu.nil?
      end
      project_medias = ProjectMedia.where(id: Assignment.where(user_id: user.id, assigned_type: 'Annotation').joins("INNER JOIN annotations a ON a.annotation_type = 'task' AND a.id = assignments.assigned_id").distinct('a.annotated_id').select('a.annotated_id AS pmid').map(&:pmid))
      project_medias.each do |project_media|
        User.set_assignments_progress(user.id, project_media.id)
      end
    end
  end
end
