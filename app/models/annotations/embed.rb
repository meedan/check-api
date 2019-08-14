Dynamic.class_eval do
  after_commit :update_elasticsearch_metadata, on: [:create, :update], if: proc { |d| d.annotation_type == 'metadata' }

  def title=(title)
    self.set_metadata_field('title', title)
  end

  def description=(description)
    self.set_metadata_field('description', description)
  end

  def title
    self.get_metadata_field('title')
  end

  def description
    self.get_metadata_field('description')
  end

  def set_metadata_field(field, value)
    return unless self.annotation_type == 'metadata'
    data = begin JSON.parse(self.get_field_value('metadata_value')) rescue {} end
    data[field] = value
    self.set_fields = { metadata_value: data.to_json }.to_json
  end

  def get_metadata_field(field)
    return unless self.annotation_type == 'metadata'
    data = begin JSON.parse(self.get_field_value('metadata_value')) rescue {} end
    data[field.to_s]
  end

  def slack_notification_message_metadata
    self.annotated.slack_notification_message(true) if self.annotated.respond_to?(:slack_notification_message)
  end

  def update_elasticsearch_metadata
    unless self.annotated.nil?
      keys = %w(title description)
      if self.annotated_type == 'ProjectMedia'
        self.update_es_metadata_pm_annotation(keys)
      elsif self.annotated_type == 'Media' && self.annotated.type == 'Link'
        self.annotated.project_medias.each do |pm|
          m = pm.get_annotations('metadata').last
          self.update_elasticsearch_doc(keys, { 'title' => pm.title, 'description' => pm.description }, pm) if m.nil?
        end
      end
    end
  end

  def update_es_metadata_pm_annotation(keys)
    data = {}
    media_metadata = self.annotated.original_metadata
    overridden = self.annotated.custom_metadata
    keys.each do |k|
      data[k] = [media_metadata[k], self.send(k)] if overridden[k]
    end
    self.update_elasticsearch_doc(keys, data)
  end

  def metadata_for_registration_account(data)
    return nil unless self.annotation_type == 'metadata'
    unless data.nil?
      m = {}
      m['author_name'] = data.dig('info', 'name')
      m['author_picture'] = data.dig('info', 'image')
      m['author_url'] = data['url']
      m['description'] = data.dig('info', 'description')
      m['picture'] = data.dig('info', 'image')
      m['provider'] = data['provider']
      m['title'] = data.dig('info', 'name')
      m['url'] = data['url']
      m['username'] = data.dig('info', 'nickname') || data.dig('info', 'name')
      m['parsed_at'] = Time.now
      m['pender'] = false
      self.set_fields = { metadata_value: m.to_json }.to_json
      self.skip_check_ability = true
      self.save!
    end
  end
end
