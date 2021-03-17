namespace :check do
  desc "Send a primary email for socail login users to reset their passwors based on new signup feature"
  task send_signup_notifications: :environment do
    subject = '“Important - your email login in Check”'
    User.where.not(email: '').find_each do |u|
      unless u.encrypted_password?
        print '.'
        SecurityMailer.delay.custom_notification(u, subject)
      end
    end
  end
end
