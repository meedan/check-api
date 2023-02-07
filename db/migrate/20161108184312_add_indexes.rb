class AddIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :id
    add_index :team_users, :id
    add_index :medias, :id
  end
end
