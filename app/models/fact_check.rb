class FactCheck < ApplicationRecord
  include Article

  enum report_status: { unpublished: 0, published: 1, paused: 2 }

  attr_accessor :skip_report_update, :publish_report

  belongs_to :claim_description

  before_validation :set_language, on: :create, if: proc { |fc| fc.language.blank? }

  validates_presence_of :claim_description
  validates_uniqueness_of :claim_description_id
  validates_format_of :url, with: URI.regexp, allow_blank: true, allow_nil: true
  validate :language_in_allowed_values, :title_or_summary_exists

  after_save :update_report

  def text_fields
    ['fact_check_title', 'fact_check_summary']
  end

  def project_media
    self.claim_description&.project_media
  end

  def team_id
    self.project_media&.team_id
  end

  private

  def set_language
    languages = self.project_media&.team&.get_languages || ['en']
    self.language = languages.length == 1 ? languages.first : 'und'
  end

  def language_in_allowed_values
    allowed_languages = self.project_media&.team&.get_languages || ['en']
    allowed_languages << 'und'
    errors.add(:language, I18n.t(:"errors.messages.invalid_article_language_value")) unless allowed_languages.include?(self.language)
  end

  def title_or_summary_exists
    errors.add(:base, I18n.t(:"errors.messages.fact_check_empty_title_and_summary")) if self.title.blank? && self.summary.blank?
  end

  def update_report
    return if self.skip_report_update || !DynamicAnnotation::AnnotationType.where(annotation_type: 'report_design').exists? || self.project_media.blank?
    pm = self.project_media
    reports = pm.get_dynamic_annotation('report_design') || Dynamic.new(annotation_type: 'report_design', annotated: pm)
    data = reports.data.to_h.with_indifferent_access
    report = data[:options]
    language = self.language || pm.team.default_language
    report_language = report.to_h.with_indifferent_access[:language]
    default_use_introduction = !!reports.report_design_team_setting_value('use_introduction', language)
    default_introduction = reports.report_design_team_setting_value('introduction', language).to_s
    unless report
      report = {
        language: language,
        use_text_message: true,
        use_introduction: default_use_introduction,
        introduction: default_introduction,
        status_label: pm.status_i18n(pm.last_verification_status, { locale: language }),
        theme_color: pm.last_status_color,
        image: pm.lead_image.to_s
      }
    end
    report.merge!({
      title: self.title.to_s.strip,
      headline: self.title.to_s.strip,
      text: self.summary.to_s.strip,
      description: self.summary.to_s.strip,
      published_article_url: self.url,
      language: self.language
    })
    report.merge!({ use_introduction: default_use_introduction, introduction: default_introduction }) if language != report_language
    data[:options] = report
    unpublished_state = data[:state].blank? ? 'unpublished' : 'paused'
    data[:state] = (self.publish_report ? 'published' : unpublished_state) if data[:state].blank? || !self.publish_report.nil?
    reports.annotator = self.user || User.current
    reports.set_fields = data.to_json
    reports.skip_check_ability = true
    reports.save!
  end

  def article_elasticsearch_data(action = 'create_or_update')
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    data = action == 'destroy' ? {
        'fact_check_title' => '',
        'fact_check_summary' => '',
        'fact_check_url' => '',
        'fact_check_languages' => []
      } : {
        'fact_check_title' => self.title,
        'fact_check_summary' => self.summary,
        'fact_check_url' => self.url,
        'fact_check_languages' => [self.language]
      }
    self.index_in_elasticsearch(data)
  end
end
