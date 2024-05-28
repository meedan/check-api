class Explainer < ApplicationRecord
  include Article

  belongs_to :team

  has_annotations

  before_validation :set_team
  validates_format_of :url, with: URI.regexp, allow_blank: true, allow_nil: true
  validates_presence_of :team, :title, :description
  validate :language_in_allowed_values, unless: proc { |e| e.language.blank? }

  after_save :create_tag_texts_if_needed

  def notify_bots
    # Nothing to do for Explainer
  end

  def send_to_alegre
    # Nothing to do for Explainer
  end

  private

  def set_team
    self.team ||= Team.current
  end

  def language_in_allowed_values
    allowed_languages = self.team.get_languages || ['en']
    allowed_languages << 'und'
    errors.add(:language, I18n.t(:"errors.messages.invalid_article_language_value")) unless allowed_languages.include?(self.language)
  end

  # Class methods

  def self.create_tag_texts_if_needed(team_id, tags)
    tags.each do |tag|
      next if TagText.where(text: tag, team_id: team_id).exists?
      tag_text = TagText.new
      tag_text.text = tag
      tag_text.team_id = team_id
      tag_text.skip_check_ability = true
      tag_text.save!
    end
  end

  private

  def create_tag_texts_if_needed
    Explainer.delay.create_tag_texts_if_needed(self.team_id, self.tags) unless self.tags.blank?
  end
end
