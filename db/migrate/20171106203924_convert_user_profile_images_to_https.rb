class ConvertUserProfileImagesToHttps < ActiveRecord::Migration
  def change
    User.find_each do |user|
      url = user.profile_image
      user.update_columns(profile_image: url.gsub(/^http:/, 'https:')) if url =~ /^http:/
    end
  end
end
