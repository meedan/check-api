class AddUserIdToProjectMedia < ActiveRecord::Migration
  def change
    add_reference :project_medias, :user, index: true, foreign_key: true
    ProjectMedia.all.each do |pm|
      pm.user_id = pm.media.user_id
      pm.save!
    end
  end
end
