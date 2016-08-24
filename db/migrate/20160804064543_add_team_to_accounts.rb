class AddTeamToAccounts < ActiveRecord::Migration
  def change
    add_reference :accounts, :team, index: true, foreign_key: true
  end
end
