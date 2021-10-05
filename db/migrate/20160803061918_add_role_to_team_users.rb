class AddRoleToTeamUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :team_users, :role, :string
  end
end
