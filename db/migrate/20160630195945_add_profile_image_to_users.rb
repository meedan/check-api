class AddProfileImageToUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column(:users, :profile_image) if User.column_names.include?('profile_image')
    add_column :users, :profile_image, :string
  end
end
