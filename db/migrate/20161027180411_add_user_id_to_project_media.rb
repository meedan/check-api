class AddUserIdToProjectMedia < ActiveRecord::Migration
  def change
    add_reference :project_medias, :user, index: true, foreign_key: true
  end
end
