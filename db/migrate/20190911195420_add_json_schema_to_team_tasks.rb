class AddJsonSchemaToTeamTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :team_tasks, :json_schema, :string
  end
end
