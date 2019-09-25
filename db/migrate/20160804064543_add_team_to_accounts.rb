class AddTeamToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :team_id, :integer
    add_index :accounts, :team_id
  end
end
