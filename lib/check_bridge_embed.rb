module Check
  class BridgeEmbed

    class << self
      def notify(payload, uri)
        return if uri.to_s.blank?
        http = Net::HTTP.new(uri.host, uri.port)
        http.read_timeout = 50000 # seconds
        http.use_ssl = uri.scheme == 'https'
        request = Net::HTTP::Post.new(uri.path)
        request.body = payload
        request['X-Signature'] = Check::BridgeEmbed.notification_signature(payload)
        request['Content-Type'] = 'application/json'
        http.request(request)
      end

    end

    def self.notification_signature(payload = '')
      'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['bridge_reader_token'].to_s, payload)
    end
  end
end
