require 'active_support/concern'

module SmoochTeamBotInstallation
  extend ActiveSupport::Concern

  module ClassMethods
    TeamBotInstallation.class_eval do
      
      # Save Twitter/Facebook token and authorization URL
      after_create do
        if self.bot_user.identifier == 'smooch'
          self.reset_smooch_authorization_token
          self.save!
        end
      end

      def reset_smooch_authorization_token
        token = SecureRandom.hex
        self.set_smooch_authorization_token = token
        self.set_smooch_twitter_authorization_url = "#{CheckConfig.get('checkdesk_base_url')}/api/users/auth/twitter?context=smooch&destination=#{CheckConfig.get('checkdesk_base_url')}/api/admin/smooch_bot/#{self.id}/authorize/twitter?token=#{token}"
        self.set_smooch_facebook_authorization_url = "#{CheckConfig.get('checkdesk_base_url')}/api/users/auth/facebook?context=smooch&destination=#{CheckConfig.get('checkdesk_base_url')}/api/admin/smooch_bot/#{self.id}/authorize/facebook?token=#{token}"
      end

      # Return a hash of enabled integrations and their information
      def smooch_enabled_integrations
        bot = Bot::Smooch
        app_id = self.get_smooch_app_id
        bot.get_installation('smooch_app_id', app_id) if bot.config.blank?
        api_instance = SmoochApi::IntegrationApi.new(bot.smooch_api_client)
        integrations = {}
        begin api_instance.list_integrations(app_id, {}).integrations.select{ |i| i.status == 'active' }.each{ |i| integrations[i.type] = i.to_hash.reject{ |k| ['_id', 'tier', 'envName', 'consumerKey', 'accessTokenKey'].include?(k.to_s) } } rescue {} end
        integrations
      end

    end
  end
end
