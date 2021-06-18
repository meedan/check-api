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

    def valid_turnio_request?(request)
      valid = !self.get_turnio_installation(request.headers['HTTP_X_TURN_HOOK_SIGNATURE'], request.raw_post).nil?
      RequestStore.store[:smooch_bot_provider] = 'TURN'
      valid
    end

    def turnio_api_get_user_data(uid, payload)
      payload['turnIo']['contacts'][0].merge({ clients: [{ platform: 'whatsapp', displayName: uid }] })
    end

    def turnio_api_get_app_name
      'TURN.IO'
    end
    
    def preprocess_turnio_message(body)
      json = JSON.parse(body)

      # Convert a message received from a WhatsApp user to the payload accepted by the Smooch Bot
      if json.dig('messages', 0, '_vnd', 'v1', 'direction') == 'inbound'
        message = json['messages'][0]
        uid = message['_vnd']['v1']['author']['id']
        {
          trigger: 'message:appUser',
          app: {
            '_id': self.config['turnio_secret']
          },
          version: 'v1.1',
          messages: [
            {
              '_id': message['id'],
              authorId: uid,
              name: json['contacts'][0]['profile']['name'],
              type: message['type'],
              text: message['text']['body'],
              source: { type: 'whatsapp' }
            }
          ],
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

    def turnio_send_message_to_user(uid, text, extra = {}, force = false)
      return if self.config['smooch_disabled'] && !force
      return if text.blank?
      payload = {
        preview_url: !text.to_s.match(/https?:\/\//).nil?,
        recipient_type: 'individual',
        to: uid,
        type: 'text',
        text: {
          body: text
        }
      }
      begin
        uri = URI('https://whatsapp.turn.io/v1/messages')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        req = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json', 'Authorization' => "Bearer #{self.config['turnio_token']}")
        req.body = payload.to_json
        http.request(req)
      rescue StandardError => e
        raise(e) if Rails.env.development?
        Rails.logger.error("[Smooch Bot] Exception when sending message #{payload.inspect} to turn.io: #{e.message}")
        e2 = SmoochBotDeliveryFailure.new('Could not send message to Smooch user!')
        self.notify_error(e2, { uid: uid, body: payload, error: e.message }, RequestStore[:request])
        nil
      end
    end
  end
end
