require 'active_support/concern'

module SmoochCapi
  extend ActiveSupport::Concern

  module ClassMethods
    def valid_capi_request?(request)
      valid = false
      if request.params['hub.mode'] == 'subscribe'
        valid = self.verified_capi_installation?(request.params['hub.verify_token'])
      else
        valid = self.get_installation do |i|
          settings = i.settings.with_indifferent_access
          request.params['token'] == settings['capi_verify_token'] && request.params.dig('entry', 0, 'id') == settings['capi_whatsapp_business_account_id']
        end.present?
      end
      RequestStore.store[:smooch_bot_provider] = 'CAPI' if valid
      valid
    end

    def verified_capi_installation?(verify_token)
      self.get_installation do |i|
        verify_token == i.settings.with_indifferent_access['capi_verify_token'].to_s
      end.present?
    end

    def capi_api_get_app_name
      'CAPI'
    end

    def capi_api_get_user_data(uid, payload)
      payload['capi'].to_h.dig('entry', 0, 'changes', 0, 'value', 'contacts', 0).to_h.merge({ clients: [{ platform: 'whatsapp', displayName: uid }] })
    end
    
    def get_capi_uid(value)
      "#{value.dig('metadata', 'display_phone_number')}:#{value.dig('contacts', 0, 'wa_id')}"
    end

    def preprocess_capi_message(body)
      json = begin JSON.parse(body) rescue {} end

      # If body is empty and the request is valid, then this is a webhook verification
      if json.blank?
        {
          trigger: 'capi:verification',
          app: {
            '_id': ''
          },
          version: 'v1.1',
          messages: [],
          appUser: {
            '_id': '',
            'conversationStarted': true
          }
        }.with_indifferent_access

      elsif json.dig('entry', 0, 'changes', 0, 'field') == 'messages'
        value = json.dig('entry', 0, 'changes', 0, 'value')
        uid = self.get_capi_uid(value)
        message = value.dig('messages', 0)
        messages = [{
          '_id': message['id'],
          authorId: uid,
          name: value.dig('contacts', 0, 'profile', 'name'),
          type: message['type'],
          text: message.dig('text', 'body'),
          source: { type: 'whatsapp', originalMessageId: message['id'] },
          received: message['timestamp'].to_i || Time.now.to_i,
          payload: '', # TODO
          quotedMessage: {} # TODO
        }]
        {
          trigger: 'message:appUser',
          app: {
            '_id': self.config['capi_whatsapp_business_account_id']
          },
          version: 'v1.1',
          messages: messages,
          appUser: {
            '_id': uid,
            'conversationStarted': true
          },
          capi: json
        }.with_indifferent_access

      # Fallback to be sure that we at least have a valid payload
      else
        {
          trigger: 'message:other',
          app: {
            '_id': self.config['capi_whatsapp_business_account_id']
          },
          version: 'v1.1',
          messages: [],
          appUser: {
            '_id': '',
            'conversationStarted': true
          },
          capi: json
        }.with_indifferent_access
      end
    end

    def capi_send_message_to_user(uid, text, extra, force)
      payload = {}
      account, to = uid.split(':')
      return if account != self.config['capi_phone_number']
      if text.is_a?(String)
        payload = {
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: to,
          type: 'text',
          text: {
            preview_url: !text.to_s.match(/https?:\/\//).nil?,
            body: text
          }
        }
      else
        payload = { to: to }.merge(text)
      end
      # FIXME: Make it work with images
      # if extra['type'] == 'image'
      #   media_id = self.turnio_upload_image(extra['mediaUrl'])
      #   payload = {
      #     recipient_type: 'individual',
      #     to: to,
      #     type: 'image',
      #     image: {
      #       id: media_id,
      #       caption: text.to_s
      #     }
      #   }
      # end
      payload.merge!(extra.dig(:override, :whatsapp, :payload).to_h)
      payload.delete(:text) if payload[:type] == 'interactive'
      return if payload[:type] == 'text' && payload[:text][:body].blank?
      uri = URI("https://graph.facebook.com/v15.0/#{self.config['capi_phone_number_id']}/messages")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{self.config['capi_permanent_token']}")
      req.body = payload.to_json
      response = http.request(req)
      ret = nil
      if response.code.to_i < 400
        ret = response
      else
        # FIXME: Notify Sentry
      end
      ret
    end

    def capi_format_template_message(namespace, template, fallback, locale, image, placeholders)
      # TODO
    end
  end
end
