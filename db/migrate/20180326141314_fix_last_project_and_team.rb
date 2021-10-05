class FixLastProjectAndTeam < ActiveRecord::Migration[4.2]
  def change
    User.find_each do |user|
      changes = {}

      unless user.current_team_id.nil?
        team = Team.where(id: user.current_team_id).last
        changes[:current_team_id] = nil if team.nil?
      end

      unless user.current_project_id.nil?
        project = Project.where(id: user.current_project_id).last
        changes[:current_project_id] = nil if project.nil?
      end
      
      user.update_columns(changes) unless changes.empty?
    end
  end
end
