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
    self.create_auto_tasks(self.project_id)
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
    self.analysis = { title: self.media.quote } unless self.media.quote.blank?
    set_title_for_files unless self.media.file.blank?
  end

  def set_title_for_files
    title = nil
    if self.user&.login == 'smooch' && ['UploadedVideo', 'UploadedImage', 'UploadedAudio'].include?(self.media.type)
      type_count = Media.where(type: self.media.type).joins("INNER JOIN project_medias pm ON medias.id = pm.media_id")
      .where("pm.team_id = ?", self.team&.id).count
      type = self.media.type.sub('Uploaded', '').downcase
      title = "#{type}-#{self.team&.slug}-#{type_count}"
    else
      # Get original file name first
      title = File.basename(self.file.original_filename, '.*') if !self.file.blank? && self.file.respond_to?(:original_filename)
      if title.blank?
        file_path = self.media.file.path
        title = File.basename(file_path, File.extname(file_path))
      end
    end
    self.analysis = { file_title: title }
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
    url = Link.normalized(self.url, pender_key)
    Link.find_by(url: url) || Link.create(url: url, pender_key: pender_key)
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

  def create_relationship(type = Relationship.default_type)
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

  def create_claim_description
    ClaimDescription.create!(description: self.set_claim_description, project_media: self, skip_check_ability: true) unless self.set_claim_description.blank?
  end
end
