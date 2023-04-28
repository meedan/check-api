class CcDeville
  class CloudflareResponseError < StandardError; end

  def self.clear_cache_for_url(url)
    if CheckConfig.get('cloudflare_auth_email')
      # https://api.cloudflare.com/#zone-purge-files-by-url
      uri = URI("https://api.cloudflare.com/client/v4/zones/#{CheckConfig.get('cloudflare_zone')}/purge_cache")
      req = Net::HTTP::Post.new(uri.path)
      req['X-Auth-Email'] = CheckConfig.get('cloudflare_auth_email')
      req['X-Auth-Key'] = CheckConfig.get('cloudflare_auth_key')
      req['Content-Type'] = 'application/json'
      req.body = {
        'files': [url]
      }.to_json
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = uri.scheme == 'https'
      begin
        res = JSON.parse(http.request(req).body)
        raise CloudflareResponseError.new "#{res['errors'][0]['code']} #{res['errors'][0]['message']}" if !res['success']
      rescue StandardError => e
        CheckSentry.notify(e, url: url)
      end
    end
  end
end
