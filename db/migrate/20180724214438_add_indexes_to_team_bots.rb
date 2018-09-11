class AddIndexesToTeamBots < ActiveRecord::Migration
  def change
    add_index :team_bots, :bot_user_id
    add_index :team_bots, :team_author_id
    add_index :team_bots, :approved
    add_index :team_bots, :identifier, unique: true
    add_index :team_bot_installations, :team_id
    add_index :team_bot_installations, :team_bot_id
    add_index :team_bot_installations, [:team_id, :team_bot_id], unique: true
  end
end
