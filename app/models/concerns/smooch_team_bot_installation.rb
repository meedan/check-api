require 'active_support/concern'

module SmoochTeamBotInstallation
  extend ActiveSupport::Concern

  module ClassMethods
    TeamBotInstallation.class_eval do
      attr_accessor :skip_save_images

      # Save Twitter/Facebook token and authorization URL
      after_create do
        if self.bot_user.identifier == 'smooch'
          self.reset_smooch_authorization_token
          self.save!
        end
      end

      # Save greeting images
      after_save do
        if self.bot_user.identifier == 'smooch' && !self.skip_save_images && self.respond_to?(:saved_change_to_file?) && self.saved_change_to_file?
          workflows = self.get_smooch_workflows
          images_updated = false
          self.file.each_with_index do |image, i|
            next if image.blank?
            url = begin image.file.public_url rescue '' end
            workflows[i]['smooch_greeting_image'] = url
            images_updated = true
          end
          self.set_smooch_workflows = workflows
          self.skip_save_images = true
          self.save!
          Rails.cache.delete_matched("smooch:user_language:#{self.team_id}:*:confirmed") if images_updated # Make sure that users will see the new image
        end
      end

      def reset_smooch_authorization_token
        if self.bot_user.identifier == 'smooch'
          token = SecureRandom.hex
          self.set_smooch_authorization_token = token
          self.set_smooch_twitter_authorization_url = "#{CheckConfig.get('checkdesk_base_url')}/api/users/auth/twitter?context=smooch&destination=#{CheckConfig.get('checkdesk_base_url')}/api/admin/smooch_bot/#{self.id}/authorize/twitter?token=#{token}"
          self.set_smooch_facebook_authorization_url = "#{CheckConfig.get('checkdesk_base_url')}/api/users/auth/facebook?context=smooch&destination=#{CheckConfig.get('checkdesk_base_url')}/api/admin/smooch_bot/#{self.id}/authorize/facebook?token=#{token}"
        end
      end

      def smooch_integrations_api_client
        if self.bot_user.identifier == 'smooch'
          bot = Bot::Smooch
          bot.get_installation(bot.installation_setting_id_keys, self.get_smooch_app_id)
          SmoochApi::IntegrationApi.new(bot.zendesk_api_client)
        end
      end

      # Return a hash of enabled integrations and their information
      def smooch_enabled_integrations(force = false)
        if self.bot_user.identifier == 'smooch'
          Rails.cache.fetch("smooch_bot:#{self.team_id}:enabled_integrations", force: force) do
            api_instance = self.smooch_integrations_api_client
            integrations = {}
            begin api_instance.list_integrations(self.get_smooch_app_id, {}).integrations.select{ |i| i.status == 'active' }.each{ |i| integrations[i.type] = i.to_hash.reject{ |k| ['tier', 'envName', 'consumerKey', 'accessTokenKey'].include?(k.to_s) } } rescue {} end
            integrations.with_indifferent_access
          end
        end
      end

      def smooch_add_integration(type, params = {})
        if Bot::Smooch::SUPPORTED_INTEGRATIONS.include?(type) && self.bot_user.identifier == 'smooch'
          api_instance = self.smooch_integrations_api_client
          integration = SmoochApi::IntegrationCreate.new({ 'type' => type, 'displayName' => type.capitalize }.merge(params))
          begin
            api_instance.create_integration(self.get_smooch_app_id, integration)
          rescue SmoochApi::ApiError => e
            message = begin JSON.parse(e.response_body).dig('error', 'description') rescue nil end
            raise message unless message.blank?
          end
        end
      end

      def smooch_remove_integration(type)
        if Bot::Smooch::SUPPORTED_INTEGRATIONS.include?(type) && self.bot_user.identifier == 'smooch'
          api_instance = self.smooch_integrations_api_client
          integration_id = self.smooch_enabled_integrations.dig(type, '_id')
          api_instance.delete_integration(self.get_smooch_app_id, integration_id) unless integration_id.blank?
        end
      end
    end
  end
end
