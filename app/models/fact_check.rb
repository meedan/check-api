class FactCheck < ApplicationRecord
  include ClaimAndFactCheck

  attr_accessor :skip_report_update

  belongs_to :claim_description

  before_validation :set_language, on: :create, if: proc { |fc| fc.language.blank? }

  validates_presence_of :claim_description
  validates_uniqueness_of :claim_description_id
  validates_format_of :url, with: URI.regexp, allow_blank: true, allow_nil: true
  validate :language_in_allowed_values

  after_save :update_report

  def text_fields
    ['fact_check_title', 'fact_check_summary']
  end

  def project_media
    self.claim_description&.project_media
  end

  private

  def set_language
    languages = self.project_media&.team&.get_languages || ['en']
    self.language = languages.length == 1 ? languages.first : 'und'
  end

  def language_in_allowed_values
    allowed_languages = self.project_media&.team&.get_languages || ['en']
    allowed_languages << 'und'
    errors.add(:language, I18n.t(:"errors.messages.invalid_fact_check_language_value")) unless allowed_languages.include?(self.language)
  end

  def update_report
    return if self.skip_report_update || !DynamicAnnotation::AnnotationType.where(annotation_type: 'report_design').exists?
    pm = self.project_media
    reports = pm.get_dynamic_annotation('report_design') || Dynamic.new(annotation_type: 'report_design', annotated: pm)
    data = reports.data ? reports.data.with_indifferent_access : {}.with_indifferent_access
    report = data[:options]
    language = self.language || pm.team.default_language || 'en'
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
    report.merge!({ use_introduction: default_use_introduction, introduction: default_introduction }) if language != report_language && !default_introduction.blank?
    data[:options] = report
    reports.annotator = self.user || User.current
    reports.set_fields = data.to_json
    reports.save!
  end
end
