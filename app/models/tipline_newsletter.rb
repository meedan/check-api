class TiplineNewsletter < ApplicationRecord
  belongs_to :team

  validates_presence_of :introduction, :team
  validates_format_of :rss_feed_url, with: URI.regexp, allow_blank: true, allow_nil: true
  validates_inclusion_of :number_of_articles, in: 0..3
  validates_inclusion_of :send_every, in: ['everyday', 'sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
  validates_inclusion_of :language, in: ->(newsletter) { newsletter.team&.get_languages.to_a }
end
