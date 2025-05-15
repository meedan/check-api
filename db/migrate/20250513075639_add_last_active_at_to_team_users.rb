class AddLastActiveAtToTeamUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :team_users, :last_active_at, :datetime
  end
end
