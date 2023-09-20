class TiplineResource < ApplicationRecord
  include TiplineContentMultimedia

  before_validation :set_team, on: :create
  before_validation :set_uuid, on: :create
  validates_presence_of :uuid, :title, :team_id
  validates_format_of :rss_feed_url, with: URI.regexp, if: ->(resource) { resource.content_type == 'rss' }
  validates_inclusion_of :content_type, in: ['static', 'rss']
  validates_inclusion_of :language, in: ->(resource) { resource.team.get_languages.to_a }

  belongs_to :team, optional: true

  def format_as_tipline_message
    message = []
    message << "*#{self.title.strip}*" unless self.title.strip.blank?
    message << self.content unless self.content.blank?
    if self.content_type == 'rss' && !self.rss_feed_url.blank?
      message << Rails.cache.fetch("tipline_resource:rss_feed:#{Digest::MD5.hexdigest(self.rss_feed_url)}:#{self.number_of_articles}", expires_in: 15.minutes, skip_nil: true) do
        rss_feed = RssFeed.new(self.rss_feed_url)
        rss_feed.get_articles(self.number_of_articles).join("\n\n")
      end
    end
    message = message.join("\n\n")
    self.team&.get_shorten_outgoing_urls ? UrlRewriter.shorten_and_utmize_urls(message, self.team&.get_outgoing_urls_utm_code) : message
  end

  def self.content_name
    'resource'
  end

  private

  def set_uuid
    self.uuid ||= rand.to_s[2..9] # Sequence of random 8 digits for backwards compatibility
  end

  def set_team
    self.team ||= Team.current
  end
end
