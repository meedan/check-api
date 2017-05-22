require 'yaml'

namespace :check do
  desc "clean private data from the database"
  task cleandb: :environment do
    # config/cleandb.yml is an array of settings.
    begin
      cleandb_config = YAML.load(File.open(File.join(File.dirname(__FILE__), '..', '..', 'config', 'cleandb.yml')))
      exceptions = cleandb_config["email_exceptions"] if cleandb_config.has_key?("email_exceptions")
      slack_settings = cleandb_config["slack_settings"] if cleandb_config.has_key?("slack_settings")
    rescue Exception => e
      puts e.message
    end
    exceptions ||= []
    slack_settings ||= {}
    Team.find_each do |t|
      if !t.settings.blank? && t.get_slack_notifications_enabled == "1"
        slack_settings.each do |k, v|
          t.send("set_#{k}", v)
        end
      end
      t.reset_slack_notifications_enabled if slack_settings.blank?
      t.private = false
      t.save(:validate => false)
    end

    User.find_each do |u|
      u.update_columns(email: '', encrypted_password: '') unless u.email =~ /@meedan\./ || exceptions.include?(u.email)
    end
    Project.find_each do |p|
      if !p.settings.blank? && p.get_slack_notifications_enabled == "1"
        slack_settings.each do |k, v|
          p.send("set_#{k}", v) if p.respond_to?("set_#{k}")
        end
        p.reset_slack_notifications_enabled if slack_settings.blank?
        p.save(:validate => false)
      end
    end
  end
end
