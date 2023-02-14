class CreateTeamTasks < ActiveRecord::Migration[4.2]
  def change
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
      t.string :fieldset, null: false, default: ""
      t.boolean :show_in_browser_extension, null: false, default: true
      t.string :json_schema
      t.text :conditional_info
      t.timestamps null: false
    end
    add_index :team_tasks, [:team_id, :fieldset, :associated_type]
  end
end
