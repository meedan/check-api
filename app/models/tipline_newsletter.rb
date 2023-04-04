class TiplineNewsletter < ApplicationRecord
  include RssFeedHelper

  belongs_to :team
  has_paper_trail on: [:create, :destroy], save_changes: true, ignore: [:updated_at, :created_at], versions: { class_name: 'Version' }

  validates_presence_of :introduction, :team
  validates_format_of :rss_feed_url, with: URI.regexp, allow_blank: true, allow_nil: true
  validates_inclusion_of :number_of_articles, in: 0..3
  validates_inclusion_of :send_every, in: ['everyday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
  validates_inclusion_of :language, in: ->(newsletter) { newsletter.team&.get_languages.to_a }

  after_save :reschedule_delivery

  def cron_notation
    hour = self.time.hour
    # If an offset is being passed, it's in the new format
    if self.timezone.match?(/\W\d\d:\d\d/)
      timezone = self.timezone.match(/\W\d\d:\d\d/)
    else
      timezone = self.timezone.to_s.upcase
    end
    # Mapping for old-style timezones not supported by Ruby's DateTime
    timezone = {
      'PHT' => '+0800',
      'CAT' => '+0200'
    }[timezone] || timezone
    time_set = DateTime.parse("#{hour}:00 #{timezone}")
    time_utc = time_set.utc
    cron_day = nil
    if self.send_every == 'everyday'
      cron_day = '*'
    else
      days = (0..6).to_a
      day = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'].index(self.send_every)
      day += (time_utc.strftime('%w').to_i - time_set.strftime('%w').to_i)
      cron_day = days[day]
    end
    "#{time_utc.min} #{time_utc.hour} * * #{cron_day}"
  end

  def build_content(cache_hash = true)
    content = ''
    content = self.body unless self.body.blank?
    content = self.get_articles_from_rss_feed(self.rss_feed_url, self.number_of_articles).join("\n\n") unless self.rss_feed_url.blank?
    content = [self.introduction, content].reject{ |text| text.blank? }.join("\n\n")
    Rails.cache.write(self.content_hash_key, Digest::MD5.hexdigest(content)) if cache_hash
    content
  end

  def content_hash_key
    "newsletter:content_hash:#{self.id}"
  end

  def content_has_changed?
    Rails.cache.read(self.content_hash_key).to_s != Digest::MD5.hexdigest(self.build_content(false))
  end

  private

  def reschedule_delivery
    name = "newsletter:job:team:#{self.team_id}:#{self.language}"
    Sidekiq::Cron::Job.destroy(name)
    Sidekiq::Cron::Job.create(name: name, cron: self.cron_notation, class: 'TiplineNewsletterWorker', args: [self.team_id, self.language])
  end
end
