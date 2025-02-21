require 'active_support/concern'
require 'open-uri'
require 'uri'

module ProjectMediaCreators
  extend ActiveSupport::Concern

  def create_metrics_annotation
    unless self.media.url.blank? || self.media.metadata.dig('metrics').nil?
      Bot::Keep.update_metrics(self.media, self.media.metadata['metrics'])
    end
  end

  def create_claim_description_and_fact_check
    cd = ClaimDescription.create!(description: self.set_claim_description, context: self.set_claim_context, project_media: self, skip_check_ability: true) unless self.set_claim_description.blank?
    fc = nil
    unless self.set_fact_check.blank?
      fact_check = self.set_fact_check.with_indifferent_access
      fc = FactCheck.create!({
        title: fact_check['title'],
        summary: fact_check['summary'],
        language: fact_check['language'],
        url: fact_check['url'],
        publish_report: !!fact_check['publish_report'],
        signature: Digest::MD5.hexdigest([self.set_fact_check.to_json, self.team_id].join(':')),
        claim_description: cd,
        report_status: (fact_check['publish_report'] ? 'published' : 'unpublished'),
        rating: self.set_status,
        tags: self.set_tags.to_a.map(&:strip),
        skip_check_ability: true
      })
    end
    fc
  end

  private

  def create_team_tasks
    self.create_auto_tasks
  end

  def create_annotation
    unless self.set_annotation.blank?
      params = JSON.parse(self.set_annotation)
      annotation = Dynamic.new
      annotation.annotated = self
      annotation.annotation_type = params['annotation_type']
      annotation.set_fields = params['set_fields']
      annotation.disable_es_callbacks = Rails.env.to_s == 'test'
      annotation.skip_notifications = true
      annotation.save!
    end
  end

  def create_media!
    self.set_media_type if self.set_original_claim || self.media_type.blank?

    media_type, media_content, additional_args = *self.media_arguments
    self.media = Media.find_or_create_media_from_content(media_type, media_content, additional_args)
  end

  def set_quote_metadata
    media = self.media
    case media.type
    when 'Link'
      set_title_for_links
    when 'Claim'
      title = self.user&.login == 'smooch' ? build_tipline_title('text') : media.quote
      self.analysis = { title: title }
    when 'UploadedImage', 'UploadedVideo', 'UploadedAudio'
      set_title_for_files
    end
  end

  def set_title_for_files
    title = nil
    if self.set_title
      title = self.set_title
    elsif self.user&.login == 'smooch'
      type = self.media.type.sub('Uploaded', '').downcase
      title = build_tipline_title(type)
    else
      # Get original file name first
      title = File.basename(self.file.original_filename, '.*') if !self.file.blank? && self.file.respond_to?(:original_filename)
      if title.blank?
        file_path = self.media.file.path
        title = File.basename(file_path, File.extname(file_path))
      end
    end
    self.analysis = { file_title: title } unless title.blank?
  end

  def set_title_for_links
    if self.user&.login == 'smooch'
      provider = self.media.metadata['provider']
      type = ['instagram', 'twitter', 'youtube', 'facebook', 'tiktok', 'telegram'].include?(provider) ? provider : 'weblink'
      title = build_tipline_title(type)
      self.analysis = { title: title }
    end
  end

  def build_tipline_title(type)
    "#{type}-#{self.team&.slug}-#{self.id}"
  end

  def add_source_creation_log
    create_log = Version.from_partition(self.team_id).where(item_id: self.id, item_type: 'ProjectMedia', event_type: 'create_projectmedia').last
    # Log extra event to show this log in UI `Source {name} add by {author}`
    unless create_log.nil?
      source_log = create_log.dup
      source_log.meta = { add_source: true, source_name: self.source&.name }.to_json
      source_log.skip_check_ability = true
      source_log.save!
    end
  end

  protected

  def set_media_type
    original_claim = self.set_original_claim&.strip

    if original_claim && original_claim.match?(/\A#{URI::DEFAULT_PARSER.make_regexp(['http', 'https'])}\z/)
      uri = URI.parse(original_claim)
      content_type = Net::HTTP.get_response(uri)['content-type']

      case content_type
      when /^image\//
        self.media_type = 'UploadedImage'
      when /^video\//
        self.media_type = 'UploadedVideo'
      when /^audio\//
        self.media_type = 'UploadedAudio'
      else
        self.media_type = 'Link'
      end
    elsif original_claim
      self.media_type = 'Claim'
    elsif !self.url.blank?
      self.media_type = 'Link'
    elsif !self.quote.blank?
      self.media_type = 'Claim'
    end
  end

  def media_arguments
    media_type = self.media_type
    original_claim = self.set_original_claim&.strip

    if original_claim
      case media_type
      when 'UploadedImage', 'UploadedVideo', 'UploadedAudio'
         [media_type, original_claim, { has_original_claim: true }]
      when 'Claim'
         [media_type, original_claim, { has_original_claim: true }]
      when 'Link'
         [media_type, original_claim, { team: self.team, has_original_claim: true }]
      end
    else
      case media_type
      when 'UploadedImage', 'UploadedVideo', 'UploadedAudio'
         [media_type, self.file]
      when 'Claim'
         [media_type, self.quote, { quote_attributions: self.quote_attributions }]
      when 'Link'
         [media_type, self.url, { team: self.team }]
      when 'Blank'
         [media_type]
      end
    end
  end

  def set_jsonld_response(task)
    jsonld = self.media.metadata['raw']['json+ld'] if self.media.metadata.has_key?('raw')
    unless jsonld.nil?
      value = self.get_response_value(jsonld, task)
      self.set_tasks_responses[Task.slug(task['label'])] = value unless value.blank?
    end
  end

  def get_response_value(jsonld, task)
    require 'jsonpath'
    mapping = task['mapping']
    self.mapping_suggestions(task, mapping['type']).each do |name|
      return self.send(name, jsonld, mapping) if self.respond_to?(name)
    end
    data = mapping_value(jsonld, mapping)
    (!data.blank? && data.kind_of?(String)) ? mapping['prefix'].gsub(/\s+$/, '') + ' ' + data : ''
  end

  def mapping_value(jsonld, mapping)
    begin
      value = JsonPath.new(mapping['match']).first(jsonld)
    rescue
      value = nil
    end
    value
  end

  def mapping_suggestions(task, mapping_type)
    [
      "mapping_#{Task.slug(task['label'])}",
      "mapping_#{task['type']}_#{mapping_type}",
      "mapping_#{task['type']}",
    ]
  end

  def create_relationship(type = Relationship.confirmed_type)
    unless self.related_to_id.nil?
      related = ProjectMedia.where(id: self.related_to_id).last
      unless related.nil?
        Relationship.create_unless_exists(related.id, self.id, type)
      else
        raise 'Could not create related item'
      end
    end
  end

  def create_tags_in_background
    if self.set_tags.is_a?(Array)
      tags = self.set_tags.reject { |t| t.blank? }
      Tag.run_later_in(1.second, 'create_project_media_tags', self.id, tags.to_json, user_id: self.user_id) unless tags.empty?
    end
  end
end
