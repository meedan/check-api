class FactCheck < ApplicationRecord
  include ClaimAndFactCheck

  attr_accessor :skip_report_update

  belongs_to :claim_description

  validates_presence_of :summary, :title, :user, :claim_description
  validates_format_of :url, with: URI.regexp, allow_blank: true, allow_nil: true

  after_save :update_report

  def text_fields
    ['fact_check_title', 'fact_check_summary']
  end

  def project_media
    self.claim_description.project_media
  end

  private

  def update_report
    return if self.skip_report_update || !DynamicAnnotation::AnnotationType.where(annotation_type: 'report_design').exists?
    pm = self.project_media
    reports = pm.get_dynamic_annotation('report_design') || Dynamic.new(annotation_type: 'report_design', annotated: pm)
    data = reports.data ? reports.data.with_indifferent_access : {}.with_indifferent_access
    language = data[:default_language] || pm.team.default_language || 'en'
    report = data[:options].to_a.find{ |o| o[:language] == language }
    unless report
      data[:options] ||= []
      report = { language: language, use_text_message: true }
      data[:options] << report
    end
    report.merge!({
      title: self.title,
      headline: self.title,
      text: self.summary,
      description: self.summary,
      published_article_url: self.url,
      theme_color: '#333333'
    })
    reports.annotator = self.user || User.current
    reports.set_fields = data.to_json
    reports.save!
  end
end
