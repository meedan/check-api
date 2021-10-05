class RemoveUnneededIndex < ActiveRecord::Migration[4.2]
  def change
    if index_exists? :team_bot_installations, :index_team_bot_installations_on_team_id
      remove_index :team_bot_installations, name: 'index_team_bot_installations_on_team_id'
    end
  end
end
