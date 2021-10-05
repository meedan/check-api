class AddFieldsetToTeamTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :team_tasks, :fieldset, :string, null: false, default: ""
    add_index :team_tasks, :fieldset
  end
end
