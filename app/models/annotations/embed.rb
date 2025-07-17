class Embed < Dynamic
  # Re-define class variables from parent class
  @custom_optimistic_locking_options = Dynamic.custom_optimistic_locking_options
end

Dynamic.class_eval do
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
