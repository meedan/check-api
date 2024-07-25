class Explainer < ApplicationRecord
  include Article

  belongs_to :team

  has_annotations
  has_many :explainer_items
  has_many :project_medias, through: :explainer_items

  before_validation :set_team
  validates_format_of :url, with: URI.regexp, allow_blank: true, allow_nil: true
  validates_presence_of :team, :title, :description
  validate :language_in_allowed_values, unless: proc { |e| e.language.blank? }

  after_save :update_paragraphs_in_alegre

  def notify_bots
    # Nothing to do for Explainer
  end

  def send_to_alegre
    # Let's not use the same callbacks from article.rb
  end

  def update_paragraphs_in_alegre
    previous_paragraphs_count = self.description_before_last_save.to_s.gsub(/\r\n?/, "\n").split(/\n+/).size

    # Schedule to run 5 seconds later - it's a way to be sure there won't be more updates coming
    self.class.delay_for(5.seconds).update_paragraphs_in_alegre(self.id, previous_paragraphs_count, Time.now.to_f)
  end

  def self.update_paragraphs_in_alegre(id, previous_paragraphs_count, timestamp)
    explainer = Explainer.find(id)

    # Skip if the explainer was saved since this job was created (it means that there is a more recent job)
    return if explainer.updated_at.to_f > timestamp

    base_context = {
      team: explainer.team.slug,
      language: explainer.language,
      explainer_id: explainer.id
    }

    # Index paragraphs
    count = 0
    explainer.description.to_s.gsub(/\r\n?/, "\n").split(/\n+/).each do |paragraph|
      count += 1
      params = {
        doc_id: Digest::MD5.hexdigest(['explainer', explainer.id, 'paragraph', count].join(':')),
        quiet: true,
        context: base_context.merge({ paragraph: count })
      }
      Bot::Alegre.request('post', '/text/similarity/', params)
    end

    # Remove paragraphs that don't exist anymore (we delete after updating in order to avoid race conditions)
    previous_paragraphs_count.times do |i|
      next if i < count
      params = {
        doc_id: Digest::MD5.hexdigest(['explainer', explainer.id, 'paragraph', index + 1].join(':')),
        quiet: true,
        context: base_context.merge({ paragraph: count })
      }
      Bot::Alegre.request('delete', '/text/similarity/', params)
    end
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
end
