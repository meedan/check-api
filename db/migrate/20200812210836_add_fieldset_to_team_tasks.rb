class AddFieldsetToTeamTasks < ActiveRecord::Migration
  def change
    add_column :team_tasks, :fieldset, :string, null: false
    add_index :team_tasks, :fieldset
  end
end
