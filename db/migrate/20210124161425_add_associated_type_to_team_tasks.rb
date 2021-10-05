class AddAssociatedTypeToTeamTasks < ActiveRecord::Migration[4.2]
  def change
    add_column(:team_tasks, :associated_type, :string,null: false, default: "ProjectMedia") unless column_exists?(:team_tasks, :associated_type)
    add_index :team_tasks, :associated_type
    TeamTask.update_all(associated_type: 'ProjectMedia')
  end
end
