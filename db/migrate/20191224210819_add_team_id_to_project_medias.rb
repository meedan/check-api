class AddTeamIdToProjectMedias < ActiveRecord::Migration
  def change
    add_column :project_medias, :team_id, :integer
    add_index :project_medias, :team_id
    # Team.find_each do |team|
    #   puts "Updating team id for all project media under team #{team.id}..."
    #   ProjectMedia.joins(:project).where('projects.team_id' => team.id).update_all(team_id: team.id)
    # end
  end
end
