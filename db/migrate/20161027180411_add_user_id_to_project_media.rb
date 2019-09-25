class AddUserIdToProjectMedia < ActiveRecord::Migration
  def change
    add_column :project_medias, :user_id, :integer
    add_index :project_medias, :user_id
    ProjectMedia.all.each do |pm|
      pm.user_id = pm.media.user_id
      pm.save!
    end
  end
end
