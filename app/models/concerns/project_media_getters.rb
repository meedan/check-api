require 'active_support/concern'

module ProjectMediaGetters
  extend ActiveSupport::Concern

  def is_claim?
    self.media.type == "Claim"
  end

  def is_link?
    self.media.type == "Link"
  end

  def is_uploaded_image?
    self.media.type == "UploadedImage"
  end

  def is_blank?
    self.media.type == "Blank"
  end

  def is_video?
    self.media.type == "UploadedVideo"
  end

  def is_audio?
    self.media.type == "UploadedAudio"
  end

  def is_image?
    self.is_uploaded_image?
  end

  def is_text?
    self.is_claim? || self.is_link?
  end

  def is_media?
    self.is_image? || self.is_audio? || self.is_video?
  end

  def report_type
    self.media.class.name.downcase
  end

  def picture
    Concurrent::Future.execute(executor: POOL) do
      self.lead_image
    end
  end

  def lead_image
    self.media&.picture&.to_s
  end

  def link
    self.media&.url&.to_s
  end

  def uploaded_file_url
    self.media&.file_path
  end

  def source_name
    self.source&.name&.to_s
  end

  def team_name
    self.team&.name&.to_s
  end

  def text
    self.media.text
  end

  def full_url
    project_prefix = self.project_id.nil? ? '' : "/project/#{self.project_id}"
    "#{CheckConfig.get('checkdesk_client')}/#{self.team.slug}#{project_prefix}/media/#{self.id}"
  end

  def created_at_timestamp
    self.created_at.to_i
  end

  def updated_at_timestamp
    self.updated_at.to_i
  end

  def has_analysis_title?
    !self.analysis_title.blank?
  end

  def original_title
    self.media&.metadata&.dig('title') || self.media&.quote || self.media&.file&.file&.filename
  end

  def analysis_title
    self.analysis.dig('title')
  end

  def has_analysis_description?
    !self.analysis_description.blank?
  end

  def original_description
    self.media&.metadata&.dig('description') || self.text
  end

  def analysis_description
    self.analysis.dig('content')
  end

  def analysis_published_article_url
    self.analysis.dig('published_article_url')
  end

  def analysis_published_date
    self.analysis.dig('date_published')
  end

  def report_field_value(field, language = nil)
    default_language = self.team&.default_language || 'en'
    self.get_dynamic_annotation('report_design')&.report_design_field_value(field.to_s, language || default_language)
  end

  def report_text_title
    self.report_field_value('title')
  end

  def report_text_content
    self.report_field_value('text')
  end

  def report_visual_card_title
    self.report_field_value('headline')
  end

  def report_visual_card_content
    self.report_field_value('description')
  end

  def extracted_text
    begin self.get_dynamic_annotation('extracted_text').get_field_value('text') rescue '' end
  end

  def transcription
    begin self.get_dynamic_annotation('transcription').get_field_value('text') rescue '' end
  end
end
