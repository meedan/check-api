require 'active_support/concern'

module SmoochTurnio
  extend ActiveSupport::Concern

  module ClassMethods
    def get_turnio_installation(signature, data)
      self.get_installation do |i|
        secret = i.settings.with_indifferent_access['turnio_secret'].to_s
        unless secret.blank?
          Base64.encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), secret, data)).chomp == signature
        end
      end
    end

    def get_whatsapp_installation(phone, secret)
      self.get_installation do |i|
        secret == i.settings.with_indifferent_access['turnio_secret'].to_s && phone == i.settings.with_indifferent_access['turnio_phone'].to_s
      end
    end

    def valid_turnio_request?(request)
      valid = !self.get_whatsapp_installation(request.headers['HTTP_X_WA_ACCOUNT_ID'], request.params[:secret]).nil? || !self.get_turnio_installation(request.headers['HTTP_X_TURN_HOOK_SIGNATURE'], request.raw_post).nil?
      RequestStore.store[:smooch_bot_provider] = 'TURN'
      valid
    end

    def turnio_api_get_user_data(uid, payload)
      payload['turnIo'].to_h['contacts'].to_a[0].to_h.merge({ clients: [{ platform: 'whatsapp', displayName: uid }] })
    end

    def turnio_api_get_app_name
      'TURN.IO'
    end

    def turnio_format_template_message(namespace, template, _fallback, locale, file_url, placeholders, file_type = 'image', preview_url = true)
      components = []
      components << { type: 'header', parameters: [{ type: file_type, file_type => { link: file_url } }] } unless file_url.blank?
      body = []
      placeholders.each do |placeholder|
        body << { type: 'text', text: placeholder.gsub(/\s+/, ' ') }
      end
      components << { type: 'body', parameters: body } unless body.empty?
      {
        type: 'template',
        preview_url: preview_url,
        template: {
          namespace: namespace,
          name: template,
          language: {
            code: locale,
            policy: 'deterministic'
          },
          components: components
        }
      }
    end

    def get_turnio_host
      self.config['turnio_host'] || 'https://whatsapp.turn.io'
    end

    def turnio_http_connection(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      ca_file_path = File.join(Rails.root, 'tmp', "#{Digest::MD5.hexdigest(self.config['turnio_cacert'].to_s)}.crt")
      File.atomic_write(ca_file_path) { |file| file.write(self.config['turnio_cacert'].to_s) } unless File.exist?(ca_file_path)
      http.ca_file = ca_file_path
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http
    end

    def store_turnio_media(media_id, mime_type)
      uri = URI("#{self.get_turnio_host}/v1/media/#{media_id}")
      http = self.turnio_http_connection(uri)
      req = Net::HTTP::Get.new(uri.request_uri, 'Authorization' => "Bearer #{self.config['turnio_token']}")
      response = http.request(req)
      path = "turnio/#{media_id}"
      CheckS3.write(path, mime_type, response.body)
      CheckS3.public_url(path)
    end

    def convert_turnio_message_type(type)
      type == 'voice' ? 'audio' : type
    end

    def get_turnio_message_event(json)
      event = 'unknown'
      if json.dig('messages', 0, '_vnd', 'v1', 'direction') == 'inbound' || json.dig('messages', 0, 'from')
        event = 'user_sent_message'
      elsif json.dig('statuses', 0, 'status') == 'delivered'
        event = 'user_received_message'
      elsif json.dig('statuses', 0, 'status') == 'failed'
        event = 'user_could_not_receive_message'
      end
      event
    end

    def get_turnio_message_text(message)
      Bot::Smooch.get_capi_message_text(message)
    end

    def get_turnio_message_uid(message)
      message.dig('_vnd', 'v1', 'author', 'id') || "#{self.config['turnio_phone']}:#{message['from']}"
    end

    def preprocess_turnio_message(body)
      json = JSON.parse(body)
      message_event = self.get_turnio_message_event(json)

      # Convert a message received from a WhatsApp user to the payload accepted by the Smooch Bot
      if message_event == 'user_sent_message'
        message = json['messages'][0]
        uid = self.get_turnio_message_uid(message)
        messages = [{
          '_id': message['id'],
          authorId: uid,
          name: json['contacts'][0]['profile']['name'],
          type: self.convert_turnio_message_type(message['type']),
          text: self.get_turnio_message_text(message),
          source: { type: 'whatsapp', originalMessageId: message['id'] },
          received: message['timestamp'].to_i || Time.now.to_i,
          payload: message.dig('interactive', 'list_reply', 'id') || message.dig('interactive', 'button_reply', 'id'),
          quotedMessage: { content: { '_id' => message.dig('context', 'id') } }
        }]
        messages[0].merge!(Bot::Smooch.convert_media_information(message))
        {
          trigger: 'message:appUser',
          app: {
            '_id': self.config['turnio_secret']
          },
          version: 'v1.1',
          messages: messages,
          appUser: {
            '_id': uid,
            'conversationStarted': true
          },
          turnIo: json
        }.with_indifferent_access

      # User received message
      elsif message_event == 'user_received_message'
        status = json['statuses'][0]
        {
          trigger: 'message:delivery:channel',
          app: {
            '_id': self.config['turnio_secret']
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
            '_id': "#{self.config['turnio_phone']}:#{status['recipient_id'] || status.dig('message', 'recipient_id')}",
            'conversationStarted': true
          },
          timestamp: status['timestamp'].to_i,
          turnIo: json
        }.with_indifferent_access

      # Could not deliver message (probably it's outside the 24-hours window)
      elsif message_event == 'user_could_not_receive_message'
        status = json['statuses'][0]
        {
          trigger: 'message:delivery:failure',
          app: {
            '_id': self.config['turnio_secret']
          },
          destination: {
            type: 'whatsapp'
          },
          error: {
            underlyingError: {
              errors: [{ code: 470 }]
            }
          },
          version: 'v1.1',
          message: {
            '_id': status['id'],
            'type': 'text'
          },
          appUser: {
            '_id': "#{self.config['turnio_phone']}:#{status['recipient_id'] || status.dig('message', 'recipient_id')}",
            'conversationStarted': true
          },
          timestamp: status['timestamp'].to_i,
          turnIo: json
        }.with_indifferent_access

      # Fallback to be sure that we at least have a valid payload
      else
        {
          trigger: 'message:other',
          app: {
            '_id': self.config['turnio_secret']
          },
          version: 'v1.1',
          messages: [],
          appUser: {
            '_id': '',
            'conversationStarted': true
          },
          turnIo: json
        }.with_indifferent_access
      end
    end

    def turnio_upload_image(url)
      require 'open-uri'
      uri = URI("#{self.get_turnio_host}/v1/media")
      http = self.turnio_http_connection(uri)
      req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'image/png', 'Authorization' => "Bearer #{self.config['turnio_token']}")
      req.body = URI(url).open.read
      response = http.request(req)
      JSON.parse(response.body).dig('media', 0, 'id')
    end

    def turnio_send_message_to_user(uid, text, extra = {}, _force = false)
      payload = {}
      account, to = uid.split(':')
      return if account != self.config['turnio_phone']
      if text.is_a?(String)
        payload = {
          preview_url: !text.to_s.match(/https?:\/\//).nil?,
          recipient_type: 'individual',
          to: to,
          type: 'text',
          text: {
            body: text
          }
        }
      else
        payload = { to: to }.merge(text)
      end
      if extra['type'] == 'image'
        media_id = self.turnio_upload_image(extra['mediaUrl'])
        payload = {
          recipient_type: 'individual',
          to: to,
          type: 'image',
          image: {
            id: media_id,
            caption: text.to_s
          }
        }
      end
      payload.merge!(extra.dig(:override, :whatsapp, :payload).to_h)
      payload.delete(:text) if payload[:type] == 'interactive'
      return if payload[:type] == 'text' && payload[:text][:body].blank?
      uri = URI("#{self.get_turnio_host}/v1/messages")
      http = self.turnio_http_connection(uri)
      req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{self.config['turnio_token']}")
      req.body = payload.to_json
      response = http.request(req)
      if response.code.to_i >= 400
        response_body = Bot::Smooch.safely_parse_response_body(response)
        errors = response_body&.dig('errors')
        errors.to_a.each do |error|
          e = Bot::Smooch::TurnioMessageDeliveryError.new("(#{error.dig('code')}) #{error.dig('title')}")
          CheckSentry.notify(e,
            uid: uid,
            error: error,
            type: payload.dig(:type),
            template_name: payload.dig(:template, :name),
            template_language: payload.dig(:template, :language, :code)
          )
        end
      end
      response
    end
  end
end
