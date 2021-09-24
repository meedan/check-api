class AddTeamToAccounts < ActiveRecord::Migration[4.2]
  def change
    add_column :accounts, :team_id, :integer
    add_index :accounts, :team_id
  end
end
