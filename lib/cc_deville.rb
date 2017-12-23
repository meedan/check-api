class CcDeville
  include ERB::Util

  def initialize(host, token, httpauth = nil)
    @host = host
    @token = token
    @httpauth = httpauth
  end

  def self.clear_cache_for_url(url)
    if CONFIG['cc_deville_host'].present? && CONFIG['cc_deville_token'].present?
      cc = CcDeville.new(CONFIG['cc_deville_host'], CONFIG['cc_deville_token'], CONFIG['cc_deville_httpauth'])
      cc.clear_cache(url)
    end
  end

  def clear_cache(url)
    response = make_request('delete', 'purge', url_encode(url))
    code = response.code.to_i
    Rails.logger.info "[cc-deville] Response for `DELETE /purge?url=#{url}` was #{code}"
    code
  end 

  private

  def make_request(verb, endpoint, url)
    uri = URI.join(@host, endpoint)
    klass = "Net::HTTP::#{verb.camelize}".constantize
    request = klass.new(uri.path + '?url=' + url)
    unless @httpauth.blank?
      username, password = @httpauth.split(':')
      request.basic_auth username, password
    end
    request.add_field('x-cc-deville-token', @token)
    http = Net::HTTP.new(uri.hostname, uri.port)
    http.use_ssl = uri.scheme == 'https'
    http.request(request)
  end
end
