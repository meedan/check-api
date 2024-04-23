class AddTeamIdToApiKeys < ActiveRecord::Migration[6.1]
  def change
    add_column :api_keys, :team_id, :integer
  end
end
