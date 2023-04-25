require 'active_support/concern'

module SmoochCapi
  extend ActiveSupport::Concern

  module ClassMethods
    def valid_capi_request?(request)
      valid = false
      if request.params['hub.mode'] == 'subscribe'
        valid = self.verified_capi_installation?(request.params['hub.verify_token'])
      elsif !request.params['token'].blank?
        valid = self.get_installation do |i|
          settings = i.settings.with_indifferent_access
          request.params['token'] == settings['capi_verify_token'] && request.params.dig('entry', 0, 'id') == settings['capi_whatsapp_business_account_id'] && !settings['capi_whatsapp_business_account_id'].blank?
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

    def get_capi_message_text(message)
      message.dig('text', 'body') || message.dig('interactive', 'list_reply', 'title') || message.dig('interactive', 'button_reply', 'title') || message.dig(message['type'], 'caption') || ''
    end

    def store_capi_media(media_id, mime_type)
      uri = URI("https://graph.facebook.com/v15.0/#{media_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Get.new(uri.request_uri, 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{self.config['capi_permanent_token']}")
      response = http.request(req)
      media_url = JSON.parse(response.body)['url']

      uri = URI(media_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Get.new(uri.request_uri, 'Authorization' => "Bearer #{self.config['capi_permanent_token']}")
      response = http.request(req)
      path = "capi/#{media_id}"
      CheckS3.write(path, mime_type, response.body)
      CheckS3.public_url(path)
    end

    def preprocess_capi_message(body)
      json = begin JSON.parse(body) rescue {} end
      app_id = self.config['capi_whatsapp_business_account_id']

      # If body is empty and the request is valid, then this is a webhook verification
      if json.blank?
        {
          trigger: 'capi:verification',
          app: {
            '_id': app_id
          },
          version: 'v1.1',
          messages: [],
          appUser: {
            '_id': '',
            'conversationStarted': true
          }
        }.with_indifferent_access

      # User sent a message
      elsif json.dig('entry', 0, 'changes', 0, 'value', 'messages')
        value = json.dig('entry', 0, 'changes', 0, 'value')
        uid = self.get_capi_uid(value)
        message = value.dig('messages', 0)
        messages = [{
          '_id': message['id'],
          authorId: uid,
          name: value.dig('contacts', 0, 'profile', 'name'),
          type: message['type'],
          text: self.get_capi_message_text(message),
          source: { type: 'whatsapp', originalMessageId: message['id'] },
          received: message['timestamp'].to_i || Time.now.to_i,
          payload: message.dig('interactive', 'list_reply', 'id') || message.dig('interactive', 'button_reply', 'id'),
          quotedMessage: { content: { '_id' => message.dig('context', 'id') } }
        }]
        messages[0].merge!(Bot::Smooch.convert_media_information(message))
        {
          trigger: 'message:appUser',
          app: {
            '_id': app_id
          },
          version: 'v1.1',
          messages: messages,
          appUser: {
            '_id': uid,
            'conversationStarted': true
          },
          capi: json
        }.with_indifferent_access

      # User received message
      elsif json.dig('entry', 0, 'changes', 0, 'value', 'statuses', 0, 'status') == 'delivered'
        status = json.dig('entry', 0, 'changes', 0, 'value', 'statuses', 0)
        {
          trigger: 'message:delivery:channel',
          app: {
            '_id': app_id
          },
          destination: {
            type: 'whatsapp'
          },
          version: 'v1.1',
          message: {
            '_id': status['id'],
            'type': 'text'
          },
          appUser: {
            '_id': "#{self.config['capi_phone_number']}:#{status['recipient_id'] || status.dig('message', 'recipient_id')}",
            'conversationStarted': true
          },
          timestamp: status['timestamp'].to_i,
          capi: json
        }.with_indifferent_access

      # User didn't receive message because 24 hours have passed since the last message from the user
      elsif json.dig('entry', 0, 'changes', 0, 'value', 'statuses', 0, 'status') == 'failed'
        status = json.dig('entry', 0, 'changes', 0, 'value', 'statuses', 0)
        error_code = status.dig('errors', 0, 'code')
        {
          trigger: 'message:delivery:failure',
          app: {
            '_id': app_id
          },
          destination: {
            type: 'whatsapp'
          },
          error: {
            underlyingError: {
              errors: [{ code: error_code }]
            }
          },
          version: 'v1.1',
          message: {
            '_id': status['id'],
            'type': 'text'
          },
          appUser: {
            '_id': "#{self.config['capi_phone_number']}:#{status['recipient_id'] || status.dig('message', 'recipient_id')}",
            'conversationStarted': true
          },
          timestamp: status['timestamp'].to_i,
          capi: json
        }.with_indifferent_access

      # Fallback to be sure that we at least have a valid payload
      else
        {
          trigger: 'message:other',
          app: {
            '_id': app_id
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

    def capi_send_message_to_user(uid, text, extra, _force = false)
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
        payload = {
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: to
        }.merge(text)
      end
      if extra['type'] == 'image'
        payload = {
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: to,
          type: 'image',
          image: {
            link: extra['mediaUrl'],
            caption: text.to_s
          }
        }
      end
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
        # FIXME: Understand different errors that can be returned from Cloud API and have specific reports
        # response_body = self.safely_parse_response_body(response)
        e = Bot::Smooch::CapiMessageDeliveryError.new('Could not send message using WhatsApp Cloud API')
        CheckSentry.notify(e, {
          uid: uid,
          type: payload.dig(:type),
          template_name: payload.dig(:template, :name),
          template_language: payload.dig(:template, :language, :code)
        })
      end
      ret
    end

    def capi_format_template_message(_namespace, template, _fallback, locale, image, placeholders)
      components = []
      components << { type: 'header', parameters: [{ type: 'image', image: { link: image } }] } unless image.blank?
      body = []
      placeholders.each do |placeholder|
        body << { type: 'text', text: placeholder.to_s.gsub(/\s+/, ' ') }
      end
      components << { type: 'body', parameters: body } unless body.empty?
      {
        type: 'template',
        template: {
          name: template,
          language: {
            code: locale
          },
          components: components
        }
      }
    end
  end
end
