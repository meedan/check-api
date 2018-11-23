class SetAssignmentsProgressCache < ActiveRecord::Migration
  def change
    assignees = Assignment.all.distinct(:user_id)
    n = assignees.count
    i = 0
    assignees.each do |assignment|
      i += 1
      puts "#{i}/#{n}) Setting progress cache for assignments of user with id #{assignment.user_id}"
      user = assignment.user
      next if user.nil?
      user.teams.each do |team|
        tu = TeamUser.where(team_id: team.id, user_id: user.id).last
        TeamUser.set_assignments_progress(user.id, team.id) unless tu.nil?
      end
      Annotation.project_media_assigned_to_user(user).each do |project_media|
        User.set_assignments_progress(user.id, project_media.id)
      end
    end
  end
end
