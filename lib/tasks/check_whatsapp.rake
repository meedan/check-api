require 'base64'
require 'net/http'

namespace :check do
  namespace :whatsapp do

    def call_whatsapp_api(endpoint, path, payload, token, verb = 'Post', auth_type = 'Bearer')
      uri = URI("#{endpoint}/#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = "Net::HTTP::#{verb}".constantize.new(uri.request_uri, 'Content-Type' => 'application/json', 'Authorization' => "#{auth_type} #{token}")
      req.body = payload.to_json if ['Post', 'Patch'].include?(verb)
      response = http.request(req)
      raise "Request to WhatsApp API failed with HTTP response code #{response.code} and body #{response.body}" if response.code.to_i >= 400
      JSON.parse(response.body)
    end

    # Generate token (valid for 7 days)
    # Each instance / phone number / tipline has its own endpoint, user and password
    desc "Generate a token for WhatsApp API which is valid for 7 days, for example: $ bundle exec rake 'check:whatsapp:generate_token[endpoint,user,password]'"
    task generate_token: :environment do |_t, args|
      endpoint, user, token = args.to_a
      raise 'Please pass the endpoint URL, user and token as parameters' if endpoint.blank? || user.blank? || token.blank?
      auth = Base64.encode64("#{user}:#{token}").chomp
      response = call_whatsapp_api(endpoint, 'v1/users/login', {}, auth, 'Post', 'Basic')
      puts response.dig('users', 0, 'token')
    end

    # Get settings
    desc "Get settings (e.g., webhook) for a given instance, for example: $ bundle exec rake 'check:whatsapp:get_settings[endpoint,token]'"
    task get_settings: :environment do |_t, args|
      endpoint, token = args.to_a
      raise 'Please pass the endpoint URL and token as parameters... if you do not a token, generate one with check:whatsapp:generate_token' if endpoint.blank? || token.blank?
      response = call_whatsapp_api(endpoint, 'v1/settings/application', {}, token, 'Get')
      puts response.inspect
    end

    # Set webhook
    desc "Set webhook for a given instance, for example: $ bundle exec rake 'check:whatsapp:set_webhook[endpoint,check-webhook-url,token]'"
    task set_webhook: :environment do |_t, args|
      endpoint, check_webhook_url, token = args.to_a
      raise 'Please pass the endpoint URL, Check webhook URL (e.g., https://check-api.checkmedia.org/api/webhooks/smooch) and token as parameters... if you do not a token, generate one with check:whatsapp:generate_token' if endpoint.blank? || check_webhook_url.blank? || token.blank?
      response = call_whatsapp_api(endpoint, 'v1/settings/application', { webhooks: { url: check_webhook_url } }, token, 'Patch')
      puts response.inspect
    end

  end
end
