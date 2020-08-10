class AddIndexToProjectMediasUserId < ActiveRecord::Migration
  def change
    add_index :project_medias, :user_id
  end
end
