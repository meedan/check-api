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

    def get_whatsapp_installation(account_id)
      self.get_installation do |i|
        account_id == i.settings.with_indifferent_access['turnio_secret'].to_s
      end
    end

    def valid_turnio_request?(request)
      valid = !self.get_whatsapp_installation(request.headers['HTTP_X_WA_ACCOUNT_ID']).nil? || !self.get_turnio_installation(request.headers['HTTP_X_TURN_HOOK_SIGNATURE'], request.raw_post).nil?
      RequestStore.store[:smooch_bot_provider] = 'TURN'
      valid
    end

    def turnio_api_get_user_data(uid, payload)
      payload['turnIo'].to_h['contacts'].to_a[0].to_h.merge({ clients: [{ platform: 'whatsapp', displayName: uid }] })
    end

    def turnio_api_get_app_name
      'TURN.IO'
    end

    def turnio_format_template_message(namespace, template, _fallback, locale, image, placeholders)
      components = []
      components << { type: 'header', parameters: [{ type: 'image', image: { link: image } }] } unless image.blank?
      body = []
      placeholders.each do |placeholder|
        body << { type: 'text', text: placeholder.gsub(/\s+/, ' ') }
      end
      components << { type: 'body', parameters: body } unless body.empty?
      {
        type: 'template',
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

    def store_turnio_media(media_id, mime_type)
      uri = URI("#{self.get_turnio_host}/v1/media/#{media_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      req = Net::HTTP::Get.new(uri.request_uri, 'Authorization' => "Bearer #{self.config['turnio_token']}")
      response = http.request(req)
      path = "turnio/#{media_id}"
      CheckS3.write(path, mime_type, response.body)
      CheckS3.public_url(path)
    end

    def convert_turnio_message_type(type)
      type == 'voice' ? 'audio' : type
    end

    def preprocess_turnio_message(body)
      json = JSON.parse(body)

      # Convert a message received from a WhatsApp user to the payload accepted by the Smooch Bot
      if json.dig('messages', 0, '_vnd', 'v1', 'direction') == 'inbound' || json.dig('messages', 0, 'from')
        message = json['messages'][0]
        uid = message.dig('_vnd', 'v1', 'author', 'id') || json.dig('messages', 0, 'from')
        messages = [{
          '_id': message['id'],
          authorId: uid,
          name: json['contacts'][0]['profile']['name'],
          type: self.convert_turnio_message_type(message['type']),
          text: message.dig('text', 'body').to_s,
          source: { type: 'whatsapp' },
          received: message['timestamp'].to_i || Time.now.to_i
        }]
        if message['type'] != 'text'
          mime_type = message.dig(message['type'], 'mime_type')
          messages[0].merge!({
            mediaUrl: self.store_turnio_media(message.dig(message['type'], 'id'), mime_type),
            mediaType: mime_type
          })
        end
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

      # User received report
      elsif json.dig('statuses', 0, 'status') == 'delivered'
        status = json['statuses'][0]
        {
          trigger: 'message:delivery:channel',
          app: {
            '_id': self.config['turnio_secret']
          },
          version: 'v1.1',
          message: {
            '_id': status['id'],
            'type': 'text'
          },
          appUser: {
            '_id': status['recipient_id'],
            'conversationStarted': true
          },
          turnIo: json
        }.with_indifferent_access

      # Could not deliver message (probably it's outside the 24-hours window)
      elsif json.dig('statuses', 0, 'status') == 'failed'
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
            '_id': status['recipient_id'],
            'conversationStarted': true
          },
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
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'image/png', 'Authorization' => "Bearer #{self.config['turnio_token']}")
      req.body = open(url).read
      response = http.request(req)
      JSON.parse(response.body).dig('media', 0, 'id')
    end

    def turnio_send_message_to_user(uid, text, extra = {}, force = false)
      return if self.config['smooch_disabled'] && !force
      payload = nil
      if text.is_a?(String)
        payload = {
          preview_url: !text.to_s.match(/https?:\/\//).nil?,
          recipient_type: 'individual',
          to: uid,
          type: 'text',
          text: {
            body: text
          }
        }
      else
        payload = { to: uid }.merge(text)
      end
      if extra['type'] == 'image'
        media_id = self.turnio_upload_image(extra['mediaUrl'])
        payload = {
          recipient_type: 'individual',
          to: uid,
          type: 'image',
          image: {
            id: media_id,
            caption: text.to_s
          }
        }
      end
      return if payload[:type] == 'text' && payload[:text][:body].blank?
      uri = URI("#{self.get_turnio_host}/v1/messages")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{self.config['turnio_token']}")
      req.body = payload.to_json
      response = http.request(req)
      if response.code.to_i == 200
        return response
      else
        e = SmoochBotDeliveryFailure.new('Could not send message to Turn.io user!')
        self.notify_error(e, { uid: uid, body: payload, error: e.message, response: response }, RequestStore[:request])
        return nil
      end
    end
  end
end
