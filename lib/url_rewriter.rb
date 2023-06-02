class UrlRewriter
  def self.shorten(url, owner)
    key = Shortener::ShortenedUrl.generate(url, owner: owner).unique_key
    host = CheckConfig.get('short_url_host_display') || CheckConfig.get('short_url_host')
    host + '/' + key
  end

  def self.utmize(url, source)
    begin
      uri = URI.parse(url)
      new_query_ar = URI.decode_www_form(uri.query.to_s) << ['utm_source', source]
      uri.query = URI.encode_www_form(new_query_ar)
      uri.to_s
    rescue
      url
    end
  end

  def self.shorten_and_utmize_urls(text, source = nil, owner = nil)
    entities = Twitter::TwitterText::Extractor.extract_urls_with_indices(text, extract_url_without_protocol: true)
    # Ruby 2.7 freezes the empty string from nil.to_s, which causes an error within the rewriter
    Twitter::TwitterText::Rewriter.rewrite_entities(text || '', entities) do |entity, _codepoints|
      url = source.blank? ? entity[:url] : self.utmize(entity[:url], source)
      self.shorten(url, owner)
    end
  end
end
