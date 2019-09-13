class AddJsonSchemaToTeamTasks < ActiveRecord::Migration
  def change
    add_column :team_tasks, :json_schema, :string
  end
end
