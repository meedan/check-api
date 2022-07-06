require 'base64'
require 'net/http'
require 'open-uri'

namespace :check do
  namespace :whatsapp do

    def call_whatsapp_api(endpoint, path, payload, token, verb = 'Post', auth_type = 'Bearer', content_type = 'application/json')
      uri = URI("#{endpoint}/#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      req = "Net::HTTP::#{verb}".constantize.new(uri.request_uri, 'Content-Type' => content_type, 'Authorization' => "#{auth_type} #{token}")
      if ['Post', 'Patch'].include?(verb)
        if content_type == 'application/json'
          req.body = payload.to_json
        else
          req.body = payload
        end
      end
      response = http.request(req)
      raise "Request to WhatsApp API failed with HTTP response code #{response.code} and body #{response.body}" if response.code.to_i >= 400
      JSON.parse(response.body)
    end

    def call_facebook_api(path, verb, params = {})
      params_string = []
      params.each do |key, value|
        value = value.to_json unless value.is_a?(String)
        params_string << "#{key}=#{value}"
      end
      url = "https://graph.facebook.com/v14.0/#{path}?#{params_string.join('&')}"
      puts "Calling #{url}..."
      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = "Net::HTTP::#{verb}".constantize.new(uri.request_uri)
      response = http.request(req)
      raise "Request to Facebook API failed with HTTP response code #{response.code} and body #{response.body}" if response.code.to_i >= 400
      JSON.parse(response.body)
    end

    # Generate token (valid for 7 days)
    # Each instance / phone number / tipline has its own endpoint, user and password
    desc "Generate a token for WhatsApp API which is valid for 7 days, for example: $ bundle exec rake 'check:whatsapp:generate_token[endpoint,user,password,team_slug]'. If a team slug is passed, the token is saved automatically."
    task generate_token: :environment do |_t, args|
      endpoint, user, token, team_slug = args.to_a
      raise 'Please pass the endpoint URL, user and token as parameters' if endpoint.blank? || user.blank? || token.blank?
      auth = Base64.encode64("#{user}:#{token}").chomp
      response = call_whatsapp_api(endpoint, 'v1/users/login', {}, auth, 'Post', 'Basic')
      token = response.dig('users', 0, 'token')
      puts token
      unless team_slug.blank?
        tbi = TeamBotInstallation.where(user: BotUser.smooch_user, team: Team.find_by_slug(team_slug)).last
        tbi.set_turnio_token = token
        tbi.save!
      end
    end

    # Set profile picture
    desc "Set profile picture for a WhatsApp account, for example: $ bundle exec rake 'check:whatsapp:set_profile_picture[endpoint,token,image_url]'"
    task set_profile_picture: :environment do |_t, args|
      endpoint, token, image_url = args.to_a
      raise 'Please pass the endpoint URL, token and image URL as parameters... if you do not have a token, generate one with check:whatsapp:generate_token' if endpoint.blank? || token.blank? || image_url.blank?
      image_data = open(image_url).read
      response = call_whatsapp_api(endpoint, 'v1/settings/profile/photo', image_data, token, 'Post', 'Bearer', 'image/png')
      puts response.inspect
    end

    # Set profile text
    desc "Set profile 'About' text for a WhatsApp account, for example: $ bundle exec rake 'check:whatsapp:set_profile_text[endpoint,token,text]'"
    task set_profile_text: :environment do |_t, args|
      endpoint, token, text = args.to_a
      raise 'Please pass the endpoint URL, token and text as parameters... if you do not have a token, generate one with check:whatsapp:generate_token' if endpoint.blank? || token.blank? || text.blank?
      response = call_whatsapp_api(endpoint, 'v1/settings/profile/about', { text: text }, token, 'Patch')
      puts response.inspect
    end

    # Get settings
    desc "Get settings (e.g., webhook) for a given instance, for example: $ bundle exec rake 'check:whatsapp:get_settings[endpoint,token]'"
    task get_settings: :environment do |_t, args|
      endpoint, token = args.to_a
      raise 'Please pass the endpoint URL and token as parameters... if you do not have a token, generate one with check:whatsapp:generate_token' if endpoint.blank? || token.blank?
      response = call_whatsapp_api(endpoint, 'v1/settings/application', {}, token, 'Get')
      puts response.inspect
    end

    # Set webhook
    desc "Set webhook for a given instance, for example: $ bundle exec rake 'check:whatsapp:set_webhook[endpoint,check-webhook-url,token]'"
    task set_webhook: :environment do |_t, args|
      endpoint, check_webhook_url, token = args.to_a
      raise 'Please pass the endpoint URL, Check webhook URL (e.g., https://check-api.checkmedia.org/api/webhooks/smooch?secret=<generate-a-random-secret>) and token as parameters... if you do not have a token, generate one with check:whatsapp:generate_token' if endpoint.blank? || check_webhook_url.blank? || token.blank?
      response = call_whatsapp_api(endpoint, 'v1/settings/application', { webhooks: { url: check_webhook_url } }, token, 'Patch')
      puts response.inspect
    end

    # Submit template
    # This can also be done through the UI: https://business.facebook.com/wa/manage/message-templates/?business_id=foo&waba_id=bar
    desc "Submit a WhatsApp message template for approval, for example: $ params='<params as JSON>' bundle exec rake 'check:whatsapp:submit_template[whatsapp-business-account-id,system-user-access-token]'"
    task submit_template: :environment do |_t, args|
      # Example for params (JSON string):
      # {"name":"report_update","language":"en_US","category":"TRANSACTIONAL","components":[{"type":"BODY","text":"Regarding what you sent on {{1}}, we have a new report update: {{2}}. Thanks for your request!"}]}
      account_id, token = args.to_a
      raise "Please pass the WhatsApp Business Account ID and Facebook Business system user access token as parameters and please set the template parameters in a $params environment variable." if account_id.blank? || token.blank? || ENV['params'].blank?
      params = JSON.parse(ENV['params'])
      params['access_token'] = token
      response = call_facebook_api("#{account_id}/message_templates", 'Post', params)
      puts response.inspect
    end

    # Get existing templates and their submission statuses
    # This can also be done through the UI: https://business.facebook.com/wa/manage/message-templates/?business_id=foo&waba_id=bar
    desc "Get WhatsApp message templates and their submission statuses, for example: $ bundle exec rake 'check:whatsapp:get_templates[whatsapp-business-account-id,system-user-access-token]'"
    task get_templates: :environment do |_t, args|
      account_id, token = args.to_a
      raise "Please pass the WhatsApp Business Account ID and Facebook Business system user access token as parameters." if account_id.blank? || token.blank?
      response = call_facebook_api("#{account_id}/message_templates", 'Get', { limit: 10, access_token: token })
      puts response.inspect
    end

    # Get template namespace
    desc "Get WhatsApp message template namespace, for example: $ bundle exec rake 'check:whatsapp:get_template_namespace[whatsapp-business-account-id,system-user-access-token]'"
    task get_template_namespace: :environment do |_t, args|
      account_id, token = args.to_a
      raise "Please pass the WhatsApp Business Account ID and Facebook Business system user access token as parameters." if account_id.blank? || token.blank?
      response = call_facebook_api("#{account_id}", 'Get', { fields: 'message_template_namespace', access_token: token })
      puts response.inspect
    end
  end
end
