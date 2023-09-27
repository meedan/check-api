class TiplineNewsletter < ApplicationRecord
  SCHEDULE_DAYS = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
  WHATSAPP_HEADER_TYPE_MAPPING = {
    'none' => 'none',
    'image' => 'image',
    'video' => 'video',
    'audio' => 'video', # WhatsApp doesn't support audio header, so we convert it to video
    'link_preview' => 'none'
  }
  NON_WHATSAPP_HEADER_TYPE_MAPPING = {
    'image' => 'image',
    'video' => 'file',
    'audio' => 'file'
  }
  MAXIMUM_ARTICLE_LENGTH = { # Number of articles => Maximum length for each article
    1 => 694,
    2 => 345,
    3 => 230
  }

  include TiplineContentMultimedia

  belongs_to :team
  has_many :tipline_newsletter_deliveries
  has_paper_trail on: [:create, :update, :destroy], save_changes: true, ignore: [:updated_at, :created_at], versions: { class_name: 'Version' }, if: proc { |_x| User.current.present? }
  has_shortened_urls

  before_validation :set_team, :set_last_scheduled_information

  serialize :send_every, JSON # List of days of the week

  validates_presence_of :team, :language
  validates :introduction, length: { maximum: 180 }, allow_blank: true, allow_nil: true
  validates_format_of :rss_feed_url, with: URI.regexp, if: ->(newsletter) { newsletter.content_type == 'rss' }
  validates_inclusion_of :language, in: ->(newsletter) { newsletter.team.get_languages.to_a }
  validates_inclusion_of :content_type, in: ['static', 'rss']
  # Should be executed only when `enabled: 1`
  validates_presence_of :send_on, if: ->(newsletter) { newsletter.content_type == 'static' && newsletter.enabled }
  validates_presence_of :time, :timezone, :introduction, if: ->(newsletter) { newsletter.enabled }
  validates_inclusion_of :number_of_articles, in: 0..3, allow_blank: true, allow_nil: true, if: ->(newsletter) { newsletter.enabled }
  validates :first_article, length: { maximum: proc { |newsletter| MAXIMUM_ARTICLE_LENGTH[newsletter.number_of_articles].to_i } }, allow_blank: true, allow_nil: true, if: proc { |newsletter| newsletter.number_of_articles >= 1 && newsletter.enabled }
  validates :second_article, length: { maximum: proc { |newsletter| MAXIMUM_ARTICLE_LENGTH[newsletter.number_of_articles].to_i } }, allow_blank: true, allow_nil: true, if: proc { |newsletter| newsletter.number_of_articles >= 2 && newsletter.enabled }
  validates :third_article, length: { maximum: proc { |newsletter| MAXIMUM_ARTICLE_LENGTH[newsletter.number_of_articles].to_i } }, allow_blank: true, allow_nil: true, if: proc { |newsletter| newsletter.number_of_articles == 3 && newsletter.enabled }
  validate :send_every_is_a_list_of_days_of_the_week, if: ->(newsletter) { newsletter.enabled }
  validate :not_scheduled_for_the_past, unless: proc { |newsletter| newsletter.time.blank? || newsletter.timezone.blank? || !newsletter.enabled }

  after_save :reschedule_delivery, unless: proc { |newsletter| newsletter.time.blank? || newsletter.timezone.blank? }

  def parsed_timezone
    timezone = self.timezone

    # If an offset is being passed, then it's in the new format... we used to support timezone names
    if self.timezone.to_s.match?(/\W\d\d:\d\d/)
      timezone = self.timezone.match(/\W\d\d:\d\d/)
    else
      timezone = self.timezone.to_s.upcase
    end

    # Mapping for old-style timezones not supported by Ruby's DateTime
    {
      'PHT' => '+0800',
      'CAT' => '+0200'
    }[timezone] || timezone
  end

  # Represent an RSS newsletter local schedule in UNIX UTC cron notation
  def cron_notation
    timezone = self.parsed_timezone
    time_set = DateTime.parse("#{self.time.hour}:#{self.time.min} #{timezone}")
    time_utc = time_set.utc

    cron_day = nil
    # Everyday
    if self.send_every.uniq.sort == SCHEDULE_DAYS.sort
      cron_day = '*'
    else
      cron_day = []
      self.send_every.each do |send_every|
        days = (0..6).to_a
        day = SCHEDULE_DAYS.index(send_every)
        # Get the right day in UTC... for example, a Saturday in a timezone can be a Sunday in UTC
        day += (time_utc.strftime('%w').to_i - time_set.strftime('%w').to_i)
        cron_day << days[day]
      end
      cron_day = cron_day.join(',')
    end

    "#{time_utc.min} #{time_utc.hour} * * #{cron_day}"
  end

  # Represent a static newsletter local schedule in UNIX UTC date object
  def scheduled_time
    DateTime.parse("#{self.send_on&.strftime("%Y-%m-%d")} #{self.time.hour}:#{self.time.min} #{self.parsed_timezone}").utc
  end

  def build_content(cache_hash = true)
    @content ||= [self.introduction, self.body].reject{ |text| text.blank? }.join("\n\n")
    Rails.cache.write(self.content_hash_key, Digest::MD5.hexdigest(@content)) if cache_hash
    @content
  end

  def content_hash_key
    "newsletter:content_hash:#{self.id}"
  end

  def content_has_changed?
    Rails.cache.read(self.content_hash_key).to_s != Digest::MD5.hexdigest(self.build_content(false))
  end

  def subscribers_count
    TiplineSubscription.where(team_id: self.team_id, language: self.language).count
  end

  def last_scheduled_by
    User.find_by_id(self.last_scheduled_by_id)
  end

  def whatsapp_template_name
    number = ['no', 'one', 'two', 'three'][self.articles.size]
    type = WHATSAPP_HEADER_TYPE_MAPPING[self.header_type]
    "newsletter_#{type}_#{number}_articles"
  end

  def articles
    return @articles unless @articles.to_a.empty?
    articles = []
    if self.content_type == 'static'
      [:first_article, :second_article, :third_article].each do |article|
        articles << self.public_send(article)
      end
    elsif self.content_type == 'rss' && !self.rss_feed_url.blank?
      articles = RssFeed.new(self.rss_feed_url).get_articles(self.number_of_articles)
    end
    @articles = articles.reject{ |article| article.blank? }.first(self.number_of_articles).collect do |article|
      if self.team.get_shorten_outgoing_urls || self.content_type == 'rss'
        UrlRewriter.shorten_and_utmize_urls(article, self.team.get_outgoing_urls_utm_code, self)
      else
        article
      end
    end
    @articles
  end

  def body
    self.articles.join("\n\n")
  end

  # For WhatsApp tiplines
  def format_as_template_message
    date = I18n.l(Time.now.to_date, locale: self.language.to_s.tr('_', '-'), format: :long)
    file_url = file_type = nil
    if ['image', 'audio', 'video'].include?(self.header_type)
      file_url = CheckS3.rewrite_url(self.header_media_url)
      file_type = WHATSAPP_HEADER_TYPE_MAPPING[self.header_type]
    end
    introduction = self.team.get_shorten_outgoing_urls ? UrlRewriter.shorten_and_utmize_urls(self.introduction, self.team.get_outgoing_urls_utm_code, self) : self.introduction
    params = [date, introduction, self.articles].flatten.reject{ |param| param.blank? }
    preview_url = (self.header_type == 'link_preview')
    Bot::Smooch.format_template_message(self.whatsapp_template_name, params, file_url, self.build_content, self.language, file_type, preview_url)
  end

  # For non-WhatsApp tiplines, ideally
  def format_as_tipline_message
    message = self.build_content
    message = (self.team.get_shorten_outgoing_urls ? UrlRewriter.shorten_and_utmize_urls(message, self.team.get_outgoing_urls_utm_code) : message)
    params = (['image', 'audio', 'video'].include?(self.header_type) ? { 'type' => NON_WHATSAPP_HEADER_TYPE_MAPPING[self.header_type], 'mediaUrl' => CheckS3.rewrite_url(self.header_media_url) } : {})
    [message, params]
  end

  def self.content_name
    'newsletter'
  end

  private

  def reschedule_delivery
    name = "newsletter:job:team:#{self.team_id}:#{self.language}"
    Sidekiq::Cron::Job.destroy(name)
    if self.content_type == 'rss'
      Sidekiq::Cron::Job.create(name: name, cron: self.cron_notation, class: 'TiplineNewsletterWorker', args: [self.team_id, self.language, Time.now.to_i])
    elsif self.content_type == 'static'
      TiplineNewsletterWorker.perform_at(self.scheduled_time, self.team_id, self.language, Time.now.to_i) if self.scheduled_time > Time.now
    end
  end

  def set_team
    self.team ||= Team.current
  end

  def send_every_is_a_list_of_days_of_the_week
    if !self.send_every.is_a?(Array) || !(self.send_every - SCHEDULE_DAYS).empty?
      errors.add(:send_every, I18n.t(:send_every_must_be_a_list_of_days_of_the_week))
    end
  end

  def set_last_scheduled_information
    if self.enabled_was == false && self.enabled == true
      self.last_scheduled_by_id = User.current&.id
      self.last_scheduled_at = Time.now
      self.last_delivery_error = nil
    end
  end

  def not_scheduled_for_the_past
    if self.enabled_was == false && self.enabled == true && self.content_type == 'static' && self.scheduled_time.past?
      field = :send_on
      field = :time if self.scheduled_time.strftime('%Y-%m-%d') == Time.now.utc.strftime('%Y-%m-%d')
      errors.add(field, I18n.t(:send_on_must_be_in_the_future))
    end
  end
end
