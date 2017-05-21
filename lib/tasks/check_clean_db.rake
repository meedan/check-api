require 'yaml'

namespace :check do
  desc "clean private data from the database"
  task cleandb: :environment do
    # config/cleandb_slack.yml is an array of slack keys settings.
    begin
      slack_settings = YAML.load(File.open(File.join(File.dirname(__FILE__), '..', '..', 'config', 'cleandb_slack.yml')))
    rescue
      slack_settings = {}
    end
    Team.find_each do |t|
      if !t.settings.blank? && t.get_slack_notifications_enabled == "1"
        slack_settings.each do |k, v|
          t.send("set_#{k}", v) if t.respond_to?("set_#{k}")
        end
      end
      t.reset_slack_notifications_enabled if slack_settings.blank?
      t.private = false
      t.save(:validate => false)
    end
    # config/cleandb_exceptions.yml is an array of emails that should not be cleaned up.
    begin
      exceptions = YAML.load(File.open(File.join(File.dirname(__FILE__), '..', '..', 'config', 'cleandb_exceptions.yml')))
    rescue Exception => e
      puts e.message
      exceptions = []
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
