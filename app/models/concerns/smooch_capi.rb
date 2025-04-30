require 'active_support/concern'

module SmoochCapi
  extend ActiveSupport::Concern

  module ClassMethods
    def should_ignore_capi_request?(request)
      return true if request.params.dig('entry', 0, 'changes', 0, 'value', 'messages', 0, 'type') == 'reaction'
      event = request.params.dig('entry', 0, 'changes', 0, 'value', 'statuses', 0, 'status').to_s
      ['read', 'sent'].include?(event)
    end

    def valid_capi_request?(request)
      valid = false
      if request.params['hub.mode'] == 'subscribe'
        valid = self.verified_capi_installation?(request.params['hub.verify_token'])
      elsif !request.params['token'].blank?
        valid = self.get_installation('whatsapp_business_account_id', request.params.dig('entry', 0, 'id')) do |i|
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
      begin
        message.dig('text', 'body') || message.dig('interactive', 'list_reply', 'title') || message.dig('interactive', 'button_reply', 'title') || message.dig(message['type'], 'caption') || ''
      rescue
        ''
      end
    end

    def store_capi_media(media_id, mime_type)
      uri = URI("https://graph.facebook.com/v15.0/#{media_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = Net::HTTP::Get.new(uri.request_uri, 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{self.config['capi_permanent_token']}")
      response = http.request(req)
      media_url = JSON.parse(response.body)['url']
      path = "capi/#{media_id}"
      self.write_file_to_s3(
        media_url,
        path,
        mime_type,
        {'Authorization' => "Bearer #{self.config['capi_permanent_token']}"}
      )
    end

    def handle_capi_system_message(message)
      if message.dig('system', 'type') == 'user_changed_number'
        old_uid = "#{self.config['capi_phone_number']}:#{message['from']}"
        new_uid = "#{self.config['capi_phone_number']}:#{message['system']['wa_id']}"
        TiplineSubscription.where(uid: old_uid).find_each do |subscription|
          subscription.uid = new_uid
          subscription.save!
        end
      end
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
        message = value.dig('messages', 0)

        # System message
        if message['type'] == 'system'
          self.handle_capi_system_message(message)
          return {
            trigger: 'message:system',
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

        uid = self.get_capi_uid(value)
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

      # User didn't receive message (for example, because 24 hours have passed since the last message from the user)
      elsif json.dig('entry', 0, 'changes', 0, 'value', 'statuses', 0, 'status') == 'failed'
        status = json.dig('entry', 0, 'changes', 0, 'value', 'statuses', 0)
        error_code = status.dig('errors', 0, 'code')
        error_message = status.dig('errors', 0, 'message')
        error_title = status.dig('errors', 0, 'title')
        {
          trigger: 'message:delivery:failure',
          app: {
            '_id': app_id
          },
          destination: {
            type: 'whatsapp'
          },
          error: {
            code: error_code,
            message: error_message,
            underlyingError: {
              errors: [{ code: error_code, title: error_title }]
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
          isFinalEvent: true,
          timestamp: status['timestamp'].to_i,
          capi: json
        }.with_indifferent_access

      # Fallback to be sure that we at least have a valid payload
      else
        CheckSentry.notify(Bot::Smooch::CapiUnhandledMessageWarning.new('CAPI unhandled message payload'), payload: json)
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

    def capi_send_message_to_user(uid, text, extra = {}, _force = false, preview_url = true)
      payload = {}
      account, to = uid.split(':')
      return if account != self.config['capi_phone_number']
      if text.is_a?(String)
        text = self.replace_placeholders(uid, text)
        payload = {
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: to,
          type: 'text',
          text: {
            preview_url: preview_url && !text.to_s.match(/https?:\/\//).nil?,
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
      elsif extra['type'] == 'video'
        payload = {
          messaging_product: 'whatsapp',
          recipient_type: 'individual',
          to: to,
          type: 'video',
          video: {
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
      Rails.logger.info("[Smooch Bot] [WhatsApp Cloud API] Sending message to #{uid} for number #{self.config['capi_phone_number_id']}. URL: #{uri} Request: #{payload.to_json}; Response: #{response.body}")
      if response.code.to_i >= 400
        error_message = begin JSON.parse(response.body)['error']['message'] rescue response.body end
        error_code = begin JSON.parse(response.body)['error']['code'] rescue nil end
        e = Bot::Smooch::CapiMessageDeliveryError.new(error_message)
        self.block_user_from_error_code(uid, error_code)
        CheckSentry.notify(e,
          uid: uid,
          type: payload.dig(:type),
          template_name: payload.dig(:template, :name),
          template_language: payload.dig(:template, :language, :code),
          error: response.body,
          error_message: error_message,
          error_code: error_code
        )
      end
      response
    end

    def capi_format_template_message(_namespace, template, _fallback, locale, file_url, placeholders, file_type = 'image', preview_url = true)
      components = []
      components << { type: 'header', parameters: [{ type: file_type, file_type => { link: file_url } }] } unless file_url.blank?
      body = []
      placeholders.each do |placeholder|
        body << { type: 'text', text: placeholder.to_s.gsub(/\s+/, ' ') }
      end
      components << { type: 'body', parameters: body } unless body.empty?
      {
        type: 'template',
        preview_url: preview_url,
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
