class RemoveUserProfileImage < ActiveRecord::Migration
  def change
    remove_column :users, :profile_image

    User.where.not(provider: "").find_each do |u|
      source = u.source
      if source.file.nil? || source.file.url == '/images/source.png'
        u.set_source_image
      end
    end
  end
end
