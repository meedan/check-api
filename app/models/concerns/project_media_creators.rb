require 'active_support/concern'

module ProjectMediaCreators
  extend ActiveSupport::Concern

  def create_metrics_annotation
    unless self.media.url.blank? || self.media.metadata.dig('metrics').nil?
      Bot::Keep.update_metrics(self.media, self.media.metadata['metrics'])
    end
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
      type = ['instagram', 'twitter', 'youtube', 'facebook', 'tiktok'].include?(provider) ? provider : 'weblink'
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

  def create_with_file(media_type = 'UploadedImage')
    klass = media_type.constantize
    m = klass.find_by(file: Media.filename(self.file)) || klass.new(file: self.file)
    m.save! if m.new_record?
    m
  end

  def create_claim
    m = Claim.new
    m.quote = self.quote
    m.quote_attributions = self.quote_attributions
    m.save!
    m
  end

  def create_link
    team = self.team || Team.current
    pender_key = team.get_pender_key if team
    url_from_pender = Link.normalized(self.url, pender_key)
    Link.find_by(url: url_from_pender) || Link.create(url: self.url, pender_key: pender_key)
  end

  def create_media
    m = nil
    self.set_media_type if self.media_type.blank?
    case self.media_type
    when 'UploadedImage', 'UploadedVideo', 'UploadedAudio'
      m = self.create_with_file(media_type)
    when 'Claim'
      m = self.create_claim
    when 'Link'
      m = self.create_link
    when 'Blank'
      m = Blank.create!
    end
    m
  end

  def set_media_type
    if !self.url.blank?
      self.media_type = 'Link'
    elsif !self.quote.blank?
      self.media_type = 'Claim'
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
        r = Relationship.new
        r.skip_check_ability = true
        r.relationship_type = type
        r.source_id = related.id
        r.target_id = self.id
        r.save!
      else
        raise 'Could not create related item'
      end
    end
  end

  def create_claim_description_and_fact_check
    cd = ClaimDescription.create!(description: self.set_claim_description, project_media: self, skip_check_ability: true) unless self.set_claim_description.blank?
    fc = nil
    unless self.set_fact_check.blank?
      fc = FactCheck.create!({
        title: self.set_fact_check['title'],
        summary: self.set_fact_check['summary'],
        language: self.set_fact_check['language'],
        url: self.set_fact_check['url'],
        publish_report: !!self.set_fact_check['publish_report'],
        claim_description: cd,
        skip_check_ability: true
      })
    end
    fc
  end

  def create_tags
    self.set_tags.each { |tag| Tag.create!(annotated: self, tag: tag, skip_check_ability: true) } unless self.set_tags.blank?
  end
end
