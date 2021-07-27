class AddIsChildToTeamTasks < ActiveRecord::Migration
  def change
    add_column :team_tasks, :is_child, :boolean, default: false
  end
end
