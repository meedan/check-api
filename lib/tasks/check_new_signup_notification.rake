namespace :check do
  desc "Send a primary email for socail login users to reset their passwors based on new signup feature"
  task send_signup_notifications: :environment do
    data = {
      subject: 'email subject',
      main_title: 'main title',
      content: 'email copy'
    }
    User.find_each do |u|
      unless u.encrypted_password?
        print '.'
        SecurityMailer.delay.custom_notification(u, data)
      end
    end
  end
end
