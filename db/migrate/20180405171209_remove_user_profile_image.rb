class RemoveUserProfileImage < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :profile_image

    User.where.not(provider: "").find_each do |u|
      source = u.source
      u.set_source_image
    end
  end
end
