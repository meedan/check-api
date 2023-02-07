class RemoveUnneededIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :team_users, name: "index_team_users_on_team_id"
    remove_index :team_users, name: "index_team_users_on_user_id"
    remove_index :versions, name: "index_versions_on_item_type"
  end
end
