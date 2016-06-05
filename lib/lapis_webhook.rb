module Lapis
  class Webhook
    def initialize(url, payload)
      @url = url
      @payload = payload
    end

    def notification_signature(payload)
      'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'], payload)
    end

    def notify
      payload = @payload.to_json
      uri = URI(@url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      request = Net::HTTP::Post.new(uri.path)
      request.body = payload
      request['X-Signature'] = notification_signature(payload)
      request['Content-Type'] = 'application/json'
      http.request(request)
    end
  end
end
