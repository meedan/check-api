require 'yaml'

namespace :check do
  namespace :data do
    desc "Clean private data from the database"
    task clean: :environment do
      begin
        cleandb_config = YAML.load(File.read(File.join(Rails.root, 'config', 'clean_db.yml')))
        exceptions = cleandb_config["email_exceptions"] if cleandb_config.has_key?("email_exceptions")
        slack_settings = cleandb_config["slack_settings"] if cleandb_config.has_key?("slack_settings")
        bot_urls = cleandb_config["bot_urls"] if cleandb_config.has_key?("bot_urls")
        bot_settings = cleandb_config["bot_settings"] if cleandb_config.has_key?("bot_settings")
      rescue Exception => e
        puts e.message
      end

      exceptions ||= []
      slack_settings ||= {}
      bot_urls ||= {}
      bot_settings ||= {}

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
        # reset encrypted for 2FA
        u.update_columns(encrypted_otp_secret: '', encrypted_otp_secret_iv: '', encrypted_otp_secret_salt: '')
        unless u.email =~ /@meedan\./ || exceptions.include?(u.email)
          u.update_columns(email: '', encrypted_password: '')
        end
      end

      Account.where.not(email: ['', nil]).find_each do |a|
        unless a.email =~ /@meedan\./ || exceptions.include?(a.email)
          a.update_columns(email: '', provider: '')
        end
      end

      Project.find_each do |p|
        if !p.settings.blank? && p.get_slack_notifications_enabled == "1"
          slack_settings.each do |k, v|
            p.send("set_#{k}", v)
          end
          p.reset_slack_notifications_enabled if slack_settings.blank?
          p.save(:validate => false)
        end
      end

      bot_urls.each do |id, url|
        BotUser.where(login: id).each do |b|
          b.set_request_url(url)
          b.save
        end
      end
      bot_settings.each do |id, settings|
        TeamBotInstallation.where(id: id).update_all(settings: JSON.parse(settings))
      end

      if ApiKey.where(access_token: 'devkey').last.nil?
        a = ApiKey.create!
        a.expire_at = a.expire_at.since(100.years)
        a.access_token = 'devkey'
        a.save!
      end
    end
  end
end
