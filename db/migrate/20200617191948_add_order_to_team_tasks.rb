class AddOrderToTeamTasks < ActiveRecord::Migration
  def change
    add_column :team_tasks, :order, :integer, default: 0
  end
end
