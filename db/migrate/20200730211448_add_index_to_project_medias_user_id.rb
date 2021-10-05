class AddIndexToProjectMediasUserId < ActiveRecord::Migration[4.2]
  def change
    add_index :project_medias, :user_id
  end
end
