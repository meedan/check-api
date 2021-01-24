class AddAnnotatedTypeToTeamTasks < ActiveRecord::Migration
  def change
    add_column :team_tasks, :annotated_type, :string, null: false, default: ""
    add_index :team_tasks, :annotated_type
    TeamTask.where(fieldset: 'metadata').update_all(annotated_type: 'ProjectMedia')
  end
end
