class CreateTeamTasks < ActiveRecord::Migration
  def change
    create_table :team_tasks do |t|
      t.string :label, null: false
      t.string :task_type, null: false
      t.text :description
      t.text :options
      t.text :project_ids
      t.boolean :required, default: false
      t.integer :team_id, null: false
      t.timestamps null: false
    end
  end
end
