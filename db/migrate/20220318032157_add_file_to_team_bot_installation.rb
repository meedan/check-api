class AddFileToTeamBotInstallation < ActiveRecord::Migration[5.2]
  def change
    add_column :team_users, :file, :string
  end
end
