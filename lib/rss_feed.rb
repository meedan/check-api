class RssFeed
  require 'rss'

  class RssLoadError < StandardError; end

  def initialize(url)
    @url = url
  end

  def url
    @url
  end

  def get_articles(count = 3)
    output = []
    begin
      URI(@url.to_s.strip).open do |rss|
        feed = RSS::Parser.parse(rss, false)
        unless feed.nil?
          feed.items.first(count).each do |item|
            title = item.title.kind_of?(String) ? item.title : item.title.content
            link = item.link.kind_of?(String) ? item.link : item.link.href
            output << title.to_s.strip + "\n" + link.to_s.strip
          end
        end
      end
    rescue
      raise RssLoadError
    end
    output
  end
end
