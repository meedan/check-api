class CreateTeamTasks < ActiveRecord::Migration[4.2]
  def change
    unless ApplicationRecord.connection.table_exists?(:team_tasks)
      create_table :team_tasks do |t|
        t.string :label, null: false
        t.string :task_type, null: false
        t.text :description
        t.text :options
        t.text :project_ids
        t.text :mapping
        t.boolean :required, default: false
        t.integer :team_id, null: false
        t.integer :order, default: 0
        t.string :associated_type, null: false, default: "ProjectMedia"
        t.timestamps null: false
      end
    end
  end
end
