class TiplineResource < ApplicationRecord
  include TiplineContentMultimedia
  include TiplineResourceNlu

  before_validation :set_team, on: :create
  before_validation :set_uuid, on: :create
  validates_presence_of :uuid, :title, :team_id
  validates_format_of :rss_feed_url, with: URI.regexp, if: ->(resource) { resource.content_type == 'rss' }
  validates_inclusion_of :content_type, in: ['static', 'rss', 'dynamic']
  validates_inclusion_of :language, in: ->(resource) { resource.team.get_languages.to_a }

  belongs_to :team, optional: true
  has_many :tipline_requests, as: :associated

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

  # This is how dynamic resources respond to user input
  def handle_user_input(message)
    response = nil
    if self.content_type == 'dynamic'
      # FIXME: Here, it currently just supports Google Civic API, but, if it becomes a feature, it should support different external APIs. Since it's just a prototype, I didn't bother to localize the strings.
      return 'This does not look like a valid address. Please try again later with a valid one.' if message['text'].to_s.size < 5 # At least a ZIP code
      if CheckConfig.get('google_api_key')
        begin
          url = "https://www.googleapis.com/civicinfo/v2/voterinfo?key=#{CheckConfig.get('google_api_key')}&address=#{ERB::Util.url_encode(message['text'].to_s.gsub(/\s+/, ' ').gsub(',', ''))}&electionId=9000"
          data = JSON.parse(Net::HTTP.get(URI(url)))
          return 'Nothing found. Please try again later with this same address or another address.' unless data.has_key?('pollingLocations')
          output = ['Here are some polling locations and some early vote sites:', '', '*POLLING LOCATIONS*', '']
          top_polling_locations = data.dig('pollingLocations').first(5)
          top_polling_locations.each { |location| output << location['address'].values.reject{ |value| value.blank? }.map(&:titleize).join("\n") + "\n" }
          output.concat(['', '*EARLY VOTE SITES*', ''])
          top_early_vote_sites = data.dig('earlyVoteSites').to_a.first(5)
          top_early_vote_sites.each { |location| output << location['address'].values.reject{ |value| value.blank? }.map(&:titleize).join("\n") + "\n" }
          response = output.join("\n")
        rescue StandardError => e
          CheckSentry.notify(e, bot: 'Smooch', context: 'Google Civic API')
          response = 'Some error happened. Please try again later.'
        end
      end
    end
    response
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
