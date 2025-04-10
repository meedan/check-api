require 'active_support/concern'

module SmoochTeamBotInstallation
  extend ActiveSupport::Concern

  module ClassMethods
    TeamBotInstallation.class_eval do
      attr_accessor :skip_save_images

      # Only super-admins can change WhatsApp token
      before_validation do
        if self.bot_user&.identifier == 'smooch'
          if User.current && !User.current.is_admin? && self.settings.to_h.with_indifferent_access['turnio_token'].to_s != self.settings_was.to_h.with_indifferent_access['turnio_token'].to_s
            self.set_turnio_token = self.settings_was.to_h.with_indifferent_access['turnio_token']
          end
        end
      end

      after_create do
        if self.bot_user&.identifier == 'smooch'
          # Save Twitter/Facebook token and authorization URL
          self.reset_smooch_authorization_token

          # Bump to v2
          self.set_smooch_version = 'v2'

          self.save!
        end
      end

      # Save greeting images
      after_save do
        if self.bot_user&.identifier == 'smooch' && !self.skip_save_images && self.respond_to?(:saved_change_to_file?) && self.saved_change_to_file?
          tbi = TeamBotInstallation.find(self.id) # Refresh lock version
          workflows = tbi.get_smooch_workflows
          images_updated = false
          self.file.each_with_index do |image, i|
            next if image.blank?
            url = begin image.file.public_url rescue '' end
            workflows[i]['smooch_greeting_image'] = url
            images_updated = true
          end
          tbi.set_smooch_workflows = workflows
          tbi.skip_save_images = true
          tbi.save!
          # Make sure that users will see the new image
          self.class.delay_for(1.second, { queue: 'smooch' }).reset_smooch_users_states(self.team_id) if images_updated
        end
      end

      # This method runs in background
      def self.reset_smooch_users_states(team_id)
        Rails.cache.delete_matched("smooch:user_language:#{team_id}:*:confirmed")
        DynamicAnnotation::Field.joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id INNER JOIN teams t ON t.id = a.annotated_id AND a.annotated_type = 'Team'").where(field_name: 'smooch_user_id', 't.id' => team_id).find_each { |f| CheckStateMachine.new(f.value).reset }
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
          smooch_integrations = Rails.cache.fetch("smooch_bot:#{self.team_id}:enabled_integrations", force: force) do
            integrations = {}
            begin self.smooch_integrations_api_client.list_integrations(self.get_smooch_app_id, {}).integrations.select{ |i| i.status == 'active' }.each{ |i| integrations[i.type] = i.to_hash.reject{ |k| ['tier', 'envName', 'consumerKey', 'accessTokenKey'].include?(k.to_s) } } rescue {} end
            integrations.with_indifferent_access
          end
          smooch_integrations.merge!({
            whatsapp: {
              type: 'whatsapp',
              phoneNumber: self.get_turnio_phone.to_s,
              status: 'active'
            }
          }) unless self.get_turnio_secret.blank?
          smooch_integrations.merge!({
            whatsapp: {
              type: 'whatsapp',
              phoneNumber: self.get_capi_phone_number.to_s,
              status: 'active'
            }
          }) unless self.get_capi_whatsapp_business_account_id.blank?
          smooch_integrations.with_indifferent_access
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

      def smooch_default_messages
        messages = {}
        keys = ['smooch_message_smooch_bot_greetings', 'submission_prompt', 'add_more_details_state', 'ask_if_ready_state',
                'search_state', 'search_no_results', 'search_result_state', 'search_result_is_relevant', 'search_submit',
                'newsletter_optin_optout', 'option_not_available', 'timeout', 'smooch_message_smooch_bot_disabled']
        self.team.get_languages.to_a.each do |language|
          messages[language] = {}
          keys.each { |key| messages[language][key.to_s] = TIPLINE_STRINGS.dig(language, key) || TIPLINE_STRINGS.dig(language.gsub(/[-_].*$/, ''), key) || TIPLINE_STRINGS.dig('en', key) }
        end
        messages
      end
    end
  end
end
