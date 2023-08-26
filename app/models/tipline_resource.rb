class TiplineResource < ApplicationRecord
  before_validation :set_uuid, on: :create
  validates_presence_of :uuid, :title, :team_id

  belongs_to :team, optional: true

  def format_as_tipline_message
    message = []
    message << "*#{self.title.strip}*" unless self.title.strip.blank?
    if self.content_type == 'static'
      message << self.content.strip unless self.content.strip.blank?
    elsif self.content_type == 'rss' && !self.rss_feed_url.blank?
      message << Rails.cache.fetch("tipline_resource:rss_feed:#{Digest::MD5.hexdigest(self.rss_feed_url)}:#{self.number_of_articles}", expires_in: 15.minutes, skip_nil: true) do
        rss_feed = RssFeed.new(self.rss_feed_url)
        rss_feed.get_articles(self.number_of_articles).join("\n\n")
      end
    end
    message = message.join("\n\n")
    self.team&.get_shorten_outgoing_urls ? UrlRewriter.shorten_and_utmize_urls(message, self.team&.get_outgoing_urls_utm_code) : message
  end

  private

  def set_uuid
    self.uuid ||= SecureRandom.hex
  end
end
