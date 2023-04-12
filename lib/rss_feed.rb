class RssFeed
  require 'rss'

  def initialize(url)
    @url = url
  end

  def url
    @url
  end

  def get_articles(count = 3)
    output = []
    URI(@url.to_s.strip).open do |rss|
      feed = RSS::Parser.parse(rss, false)
      unless feed.nil?
        feed.items.first(count).each do |item|
          output << item.title.strip + "\n" + item.link.strip
        end
      end
    end
    output
  end
end
