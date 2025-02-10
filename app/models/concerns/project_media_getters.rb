require 'active_support/concern'

module ProjectMediaGetters
  extend ActiveSupport::Concern

  def is_claim?
    self.media.type == "Claim"
  end

  def is_link?
    self.media.type == "Link"
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
    self.media.type == "UploadedImage"
  end

  def is_uploaded_media?
    self.is_image? || self.is_audio? || self.is_video?
  end

  def is_text?
    self.is_claim? || self.is_link?
  end

  def is_media?
    self.is_image? || self.is_audio? || self.is_video?
  end

  def is_imported_from_shared_feed?
    self.channel.to_h['main'] == ::CheckChannels::ChannelCodes::SHARED_DATABASE
  end

  def report_type
    self.media.class.name.downcase
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

  def text
    self.media.text
  end

  def full_url
    project_prefix = self.project_id.nil? ? '' : "/project/#{self.project_id}"
    "#{CheckConfig.get('checkdesk_client')}/#{self.team.slug}#{project_prefix}/media/#{self.id}"
  end

  def updated_at_timestamp
    self.updated_at.to_i
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

  def report_field_value(field)
    self.get_dynamic_annotation('report_design')&.report_design_field_value(field.to_s)
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

  def claim_description_content
    self.claim_description&.description
  end

  def claim_description_context
    self.claim_description&.context
  end

  def get_title
    # Maps the value of the `ProjectMedia` `title_field` column to a `ProjectMedia` method that returns that value
    title_mapping = {
      custom_title: :custom_title,
      pinned_media_id: :media_slug,
      claim_title: :claim_description_content,
      fact_check_title: :recalculate_fact_check_title
    }
    title_field = self.title_field&.to_sym
    if !title_field.blank? && title_mapping.keys.include?(title_field)
      return self.send(title_mapping[title_field]).to_s
    end
    title = self.original_title
    [self.analysis['file_title'], self.analysis['title'], self.fact_check_title(true), self.claim_description_content].each do |value|
      title = value if !value.blank? && value != '-' && value != '​'
    end
    title.to_s
  end

  def media_slug
    media = self.media
    type = case media.type
           when 'Link'
             provider = media.metadata['provider']
             ['instagram', 'twitter', 'youtube', 'facebook', 'tiktok', 'telegram'].include?(provider) ? provider : 'weblink'
           when 'Claim'
             'text'
           when 'UploadedImage', 'UploadedVideo', 'UploadedAudio'
             media.type.sub('Uploaded', '').downcase
           end
    type.blank? ? '' : build_tipline_title(type)
  end

  def get_description
    return self.fact_check_summary(true) if self.get_main_channel == CheckChannels::ChannelCodes::FETCH
    analysis_description = self.has_analysis_description? ? self.analysis_description : nil
    self.claim_description_content || analysis_description || self.original_description
  end

  def published_url
    analysis_url = self.analysis_published_article_url
    fact_check_url = self.claim_description&.fact_check&.url
    fact_check_url || analysis_url
  end

  def get_main_channel
    self.channel.with_indifferent_access[:main].to_i
  end

  def get_creator_name
    user_name = ''
    main_channel = self.get_main_channel
    if [CheckChannels::ChannelCodes::MANUAL, CheckChannels::ChannelCodes::BROWSER_EXTENSION].include?(main_channel)
      user_name = self.user&.name
    elsif CheckChannels::ChannelCodes::TIPLINE.include?(main_channel)
      user_name = 'Tipline'
    elsif [CheckChannels::ChannelCodes::FETCH, CheckChannels::ChannelCodes::API, CheckChannels::ChannelCodes::ZAPIER].include?(main_channel)
      user_name = 'Import'
    elsif main_channel == CheckChannels::ChannelCodes::WEB_FORM
      user_name = 'Web Form'
    elsif main_channel == CheckChannels::ChannelCodes::SHARED_DATABASE
      user_name = 'Shared Database'
    end
    user_name
  end

  def team_avatar
    self.team.avatar
  end

  def fact_check
    self.claim_description&.fact_check
  end

  def explainers_titles
    # Get the title for all explainer assigned to the item
    titles = Explainer.joins(:explainer_items).where('explainer_items.project_media_id = ?', self.id).map(&:title).join("\n")
    titles.blank? ? nil : titles
  end
end
