class AddProfileImageToUsers < ActiveRecord::Migration
  def change
    begin
      remove_column :users, :profile_image
    rescue
      # Column doesn't exist
    end
    add_column :users, :profile_image, :string
  end
end
