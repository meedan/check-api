class AddOtpSecretForEmailBasedUsers < ActiveRecord::Migration
  def change
  	User.where.not(encrypted_password: [nil, ""]).find_each do |u|
  		u.otp_secret = User.generate_otp_secret
  		u.skip_check_ability = true
  		u.save!
  	end
  end
end
