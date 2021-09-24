class AddIsChildToTeamTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :team_tasks, :is_child, :boolean, default: false
  end
end
