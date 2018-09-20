class RemoveUnneededIndex < ActiveRecord::Migration
  def change
    remove_index :team_bot_installations, name: 'index_team_bot_installations_on_team_id'
  end
end
