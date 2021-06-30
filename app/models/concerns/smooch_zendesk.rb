require 'active_support/concern'

module SmoochZendesk
  extend ActiveSupport::Concern

  module ClassMethods
    def valid_zendesk_request?(request)
      RequestStore.store[:smooch_bot_queue] = request.headers['X-Check-Smooch-Queue'].to_s
      key = request.headers['X-API-Key'].to_s
      installation = self.get_installation('smooch_webhook_secret', key)
      valid = !key.blank? && !installation.nil?
      RequestStore.store[:smooch_bot_provider] = 'ZENDESK'
      valid
    end

    def zendesk_api_get_messages(app_id, user_id, opts = {})
      result = nil
      api_client = self.zendesk_api_client
      api_instance = SmoochApi::ConversationApi.new(api_client)
      begin
        result = api_instance.get_messages(app_id, user_id, opts)
      rescue StandardError => e
        Rails.logger.error("[Smooch Bot] Exception for get messages : #{e.message}")
      end
      result
    end

    def zendesk_api_get_user_data(uid)
      api_client = self.zendesk_api_client
      app_id = self.config['smooch_app_id']
      api_instance = SmoochApi::AppUserApi.new(api_client)
      api_instance.get_app_user(app_id, uid).appUser.to_hash.with_indifferent_access
    end

    def zendesk_api_get_app_data(app_id)
      api_client = self.zendesk_api_client
      api_instance = SmoochApi::AppApi.new(api_client)
      api_instance.get_app(app_id)
    end

    def zendesk_api_client
      payload = { scope: 'app' }
      jwt_header = { kid: self.config['smooch_secret_key_key_id'] }
      token = JWT.encode payload, self.config['smooch_secret_key_secret'], 'HS256', jwt_header
      config = SmoochApi::Configuration.new
      config.api_key['Authorization'] = token
      config.api_key_prefix['Authorization'] = 'Bearer'
      SmoochApi::ApiClient.new(config)
    end

    def zendesk_send_message_to_user(uid, text, extra = {}, force = false)
      return if self.config['smooch_disabled'] && !force
      api_client = self.zendesk_api_client
      api_instance = SmoochApi::ConversationApi.new(api_client)
      app_id = self.config['smooch_app_id']
      params = { 'role' => 'appMaker', 'type' => 'text', 'text' => text.to_s.truncate(4096) }.merge(extra)
      # An error is raised by Smooch API if we set "preview_url: true" and there is no URL in the "text" parameter
      if text.to_s.match(/https?:\/\//)
        params.merge!({
          override: {
            whatsapp: {
              payload: {
                preview_url: true,
                type: 'text',
                text: {
                  body: text
                }
              }
            }
          }
        })
      end
      return if params['type'] == 'text' && params['text'].blank?
      message_post_body = SmoochApi::MessagePost.new(params)
      begin
        api_instance.post_message(app_id, uid, message_post_body)
      rescue SmoochApi::ApiError => e
        Rails.logger.error("[Smooch Bot] Exception when sending message #{params.inspect}: #{e.response_body}")
        e2 = SmoochBotDeliveryFailure.new('Could not send message to Smooch user!')
        self.notify_error(e2, { smooch_app_id: app_id, uid: uid, body: params, smooch_response: e.response_body }, RequestStore[:request])
        nil
      end
    end

    # https://docs.smooch.io/guide/whatsapp#shorthand-syntax
    def zendesk_format_template_message(namespace, template, fallback, locale, image, placeholders)
      data = { namespace: namespace, template: template, fallback: fallback, language: locale }
      data['header_image'] = image unless image.blank?
      output = ['&((']
      data.each do |key, value|
        output << "#{key}=[[#{value}]]"
      end
      placeholders.each do |placeholder|
        output << "body_text=[[#{placeholder.gsub(/\s+/, ' ')}]]"
      end
      output << '))&'
      output.join('')
    end
  end
end
