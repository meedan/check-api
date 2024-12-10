class Explainer < ApplicationRecord
  include Article

  belongs_to :team

  has_annotations
  has_many :explainer_items, dependent: :destroy
  has_many :project_medias, through: :explainer_items

  before_validation :set_team
  validates_format_of :url, with: URI.regexp, allow_blank: true, allow_nil: true
  validates_presence_of :team, :title, :description
  validate :language_in_allowed_values, unless: proc { |e| e.language.blank? }

  after_save :update_paragraphs_in_alegre
  after_update :detach_explainer_if_trashed

  def notify_bots
    # Nothing to do for Explainer
  end

  def send_to_alegre
    # Let's not use the same callbacks from article.rb
  end

  def as_tipline_search_result
    TiplineSearchResult.new(
      team: self.team,
      title: self.title,
      body: self.description,
      image_url: nil,
      language: self.language,
      url: self.url,
      type: :explainer,
      format: :text
    )
  end

  def update_paragraphs_in_alegre
    previous_paragraphs_count = self.description_before_last_save.to_s.gsub(/\r\n?/, "\n").split(/\n+/).reject{ |paragraph| paragraph.strip.blank? }.size

    # Schedule to run 5 seconds later - it's a way to be sure there won't be more updates coming
    self.class.delay_for(5.seconds).update_paragraphs_in_alegre(self.id, previous_paragraphs_count, Time.now.to_f)
  end

  def self.get_exported_data(query, team)
    data = [['ID', 'Title', 'Description', 'URL', 'Language']]
    team.filtered_explainers(query).find_each do |exp|
      data << [exp.id, exp.title, exp.description, exp.url, exp.language]
    end
    data
  end

  def self.update_paragraphs_in_alegre(id, previous_paragraphs_count, timestamp)
    explainer = Explainer.find_by_id(id)
    return if explainer.nil?

    # Skip if the explainer was saved since this job was created (it means that there is a more recent job)
    return if explainer.updated_at.to_f > timestamp

    base_context = {
      type: 'explainer',
      team: explainer.team.slug,
      language: explainer.language,
      explainer_id: explainer.id
    }

    models_thresholds = Explainer.get_alegre_models_and_thresholds(explainer.team_id).keys
    # Index title
    params = {
      content_hash: Bot::Alegre.content_hash_for_value(explainer.title),
      doc_id: Digest::MD5.hexdigest(['explainer', explainer.id, 'title'].join(':')),
      context: base_context.merge({ field: 'title' }),
      text: explainer.title,
      models: models_thresholds,
    }
    Bot::Alegre.index_async_with_params(params, "text")

    # Index paragraphs
    count = 0
    explainer.description.to_s.gsub(/\r\n?/, "\n").split(/\n+/).reject{ |paragraph| paragraph.strip.blank? }.each do |paragraph|
      count += 1
      params = {
        content_hash: Bot::Alegre.content_hash_for_value(paragraph.strip),
        doc_id: Digest::MD5.hexdigest(['explainer', explainer.id, 'paragraph', count].join(':')),
        context: base_context.merge({ paragraph: count }),
        text: paragraph.strip,
        models: models_thresholds,
      }
      Bot::Alegre.index_async_with_params(params, "text")
    end

    # Remove paragraphs that don't exist anymore (we delete after updating in order to avoid race conditions)
    previous_paragraphs_count.times do |index|
      next if index < count
      params = {
        doc_id: Digest::MD5.hexdigest(['explainer', explainer.id, 'paragraph', index + 1].join(':')),
        quiet: true,
        context: base_context.merge({ paragraph: count })
      }
      Bot::Alegre.request_delete_from_raw(params, "text")
    end
  end

  def self.search_by_similarity(text, language, team_id, limit)
    models_thresholds = Explainer.get_alegre_models_and_thresholds(team_id)
    context = {
      type: 'explainer',
      team: Team.find(team_id).slug
    }
    context[:language] = language unless language.nil?
    params = {
      text: text,
      models: models_thresholds.keys,
      per_model_threshold: models_thresholds,
      context: context

    }
    response = Bot::Alegre.query_sync_with_params(params, "text")
    results = response['result'].to_a.sort_by{ |result| result['_score'] }
    explainer_ids = results.collect{ |result| result.dig('context', 'explainer_id').to_i }.uniq.first(limit)
    explainer_ids.empty? ? Explainer.none : Explainer.where(team_id: team_id, id: explainer_ids)
  end

  def self.get_alegre_models_and_thresholds(team_id)
    models_thresholds = {}
    Bot::Alegre.get_similarity_methods_and_models_given_media_type_and_team_id("text", team_id, true).map do |similarity_method, model_name|
      _, value = Bot::Alegre.get_threshold_given_model_settings(team_id, "text", similarity_method, true, model_name)
      models_thresholds[model_name] = value
    end
    models_thresholds
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

  def detach_explainer_if_trashed
    if self.trashed && !self.trashed_before_last_save
      self.project_medias = []
    end
  end
end
