class TiplineNewsletter < ApplicationRecord
  SCHEDULE_DAYS = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']

  include TiplineNewsletterImage

  belongs_to :team
  has_many :tipline_newsletter_deliveries

  has_paper_trail on: [:create, :destroy], save_changes: true, ignore: [:updated_at, :created_at], versions: { class_name: 'Version' }

  mount_uploader :header_file, FileUploader

  before_validation :set_team, :set_last_scheduled_information

  serialize :send_every, JSON # List of days of the week

  validates_presence_of :time, :timezone
  validates_presence_of :introduction, :team, :language
  validates_format_of :rss_feed_url, with: URI.regexp, allow_blank: true, allow_nil: true
  validates_inclusion_of :number_of_articles, in: 0..3, allow_blank: true, allow_nil: true
  validates_inclusion_of :language, in: ->(newsletter) { newsletter.team.get_languages.to_a }
  validates_inclusion_of :header_type, in: ['none', 'link_preview', 'audio', 'video', 'image']
  validates_inclusion_of :content_type, in: ['static', 'rss']
  validate :send_every_is_a_list_of_days_of_the_week
  validate :header_file_is_supported_by_whatsapp

  after_save :reschedule_delivery
  after_commit :convert_header_file, on: [:create, :update]

  # File uploads through GraphQL require this setter
  # Accepts an array or a single file, but persists only one file
  def file=(file)
    @file_set = true
    self.header_file = [file].flatten.first
  end

  def parsed_timezone
    timezone = self.timezone

    # If an offset is being passed, then it's in the new format... we used to support timezone names
    if self.timezone.match?(/\W\d\d:\d\d/)
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
    content = [self.introduction, self.body].reject{ |text| text.blank? }.join("\n\n")
    Rails.cache.write(self.content_hash_key, Digest::MD5.hexdigest(content)) if cache_hash
    content
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
    type = {
      'none' => 'none',
      'image' => 'image',
      'video' => 'video',
      'audio' => 'audio',
      'link_preview' => 'none'
    }[self.header_type]
    "newsletter_#{type}_#{number}_articles"
  end

  def articles
    articles = []
    if self.content_type == 'static'
      [:first_article, :second_article, :third_article].each do |article|
        articles << self.public_send(article)
      end
    elsif self.content_type == 'rss' && !self.rss_feed_url.blank?
      articles = RssFeed.new(self.rss_feed_url).get_articles(self.number_of_articles)
    end
    articles.reject{ |article| article.blank? }.first(self.number_of_articles)
  end

  def body
    self.articles.join("\n\n")
  end

  def self.convert_header_file(id, file_set)
    newsletter = TiplineNewsletter.find(id)
    new_url = nil

    if newsletter.should_convert_header_image?(file_set)
      new_url = newsletter.convert_header_file_image
    end

    newsletter.update_column(:header_media_url, new_url) unless new_url.nil?
  end

  private

  def reschedule_delivery
    name = "newsletter:job:team:#{self.team_id}:#{self.language}"
    Sidekiq::Cron::Job.destroy(name)
    if self.content_type == 'rss'
      Sidekiq::Cron::Job.create(name: name, cron: self.cron_notation, class: 'TiplineNewsletterWorker', args: [self.team_id, self.language, Time.now.to_i])
    elsif self.content_type == 'static'
      TiplineNewsletterWorker.perform_at(self.scheduled_time, self.team_id, self.language, Time.now.to_i)
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
    end
  end

  def header_file_is_supported_by_whatsapp
    if self.header_type && @file_set
      case self.header_type
      when 'image'
        self.validate_header_file_image
      else
        # Nothing to validate
      end
    end
  end

  def convert_header_file
    self.class.delay_for(1.second).convert_header_file(self.id, @file_set)
  end
end
