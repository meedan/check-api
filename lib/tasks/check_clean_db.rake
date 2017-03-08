require 'yaml'

namespace :check do
  desc "clean private data from the database"
  task cleandb: :environment do
    Team.all.each do |t|
      t.reset_slack_notifications_enabled
      t.reset_slack_webhook
      t.private = false
      t.save
    end
    # config/cleandb_exceptions.yml is an array of emails that should not be cleaned up.
    begin
      exceptions = YAML.load(File.open(File.join(File.dirname(__FILE__), '..', '..', 'config', 'cleandb_exceptions.yml')))
    rescue Exception => e
      puts e.message
      exceptions = []
    end
    User.all.each do |u|
      u.update_columns(email: '', encrypted_password: '') unless u.email =~ /@meedan\./ || exceptions.include?(u.email)
    end
  end
end
