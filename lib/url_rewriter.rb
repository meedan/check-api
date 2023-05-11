class UrlRewriter
  def self.shorten(url, owner)
    key = Shortener::ShortenedUrl.generate(url, owner: owner).unique_key
    CheckConfig.get('short_url_host') + '/' + key
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

  def self.shorten_and_utmize_urls(text, source = 'check', owner = nil)
    entities = Twitter::TwitterText::Extractor.extract_urls_with_indices(text, extract_url_without_protocol: true)
    # Ruby 2.7 freezes the empty string from nil.to_s, which causes an error within the rewriter
    Twitter::TwitterText::Rewriter.rewrite_entities(text || '', entities) do |entity, _codepoints|
      self.shorten(self.utmize(entity[:url], source), owner)
    end
  end
end
