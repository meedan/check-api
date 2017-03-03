class AddIndexes < ActiveRecord::Migration
  def change
    add_index :users, :id
    add_index :team_users, :id
    add_index :project_medias, :id
    add_index :medias, :id
  end
end
