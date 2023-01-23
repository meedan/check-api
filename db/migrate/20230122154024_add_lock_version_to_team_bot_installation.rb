class AddLockVersionToTeamBotInstallation < ActiveRecord::Migration[5.2]
  def change
    add_column :team_users, :lock_version, :integer, default: 0, null: false
  end
end
