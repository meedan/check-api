class RenameTeamTaskIsChildToConditionalInfo < ActiveRecord::Migration
  def change
    remove_column :team_tasks, :is_child
    add_column :team_tasks, :conditional_info, :text
  end
end
