module RssFeedHelper
  require 'rss'
  require 'open-uri'
  
  def get_articles_from_rss_feed(url, count = 3)
    output = []
    begin
      open(url.to_s.strip) do |rss|
        feed = RSS::Parser.parse(rss, false)
        feed.items.first(count).each do |item|
          output << item.title.strip + "\n" + item.link.strip
        end unless feed.nil?
      end
    rescue StandardError => e
      output << url.to_s
      Rails.logger.info "Could not parse RSS feed from URL #{url}, error was: #{e.message}"
    end
    output
  end
end
