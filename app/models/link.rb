class Link < Media
  include PenderData

  validates :url, presence: true, on: :create
  validate :validate_pender_result_and_retry, on: :create
  validate :pender_result_is_a_media, on: :create
  validate :url_is_unique, on: :create

  after_create :set_pender_result_as_annotation, :set_account

  def domain
    host = URI.parse(URI.encode(self.url)).host unless self.url.nil?
    host.nil? ? nil : host.gsub(/^(www|m)\./, '')
  end

  def provider
    domain = self.domain
    domain.nil? ? nil : domain.gsub(/\..*/, '').capitalize
  end

  def picture
    path = ''
    begin
      pender_data = self.get_saved_pender_data
      path = pender_data['picture']
    rescue
    end
    path.to_s
  end

  def get_saved_pender_data
    begin JSON.parse(self.annotations.where(annotation_type: 'metadata').last.load.get_field_value('metadata_value')) rescue {} end
  end

  def text
    self.get_saved_pender_data['description'].to_s
  end

  def original_published_time
    published_time = self.metadata['published_at']
    return '' if published_time.to_i.zero?
    published_time.is_a?(String) ? Time.parse(published_time) : Time.at(published_time)
  end

  def media_type
    self.get_saved_pender_data['provider']
  end

  private

  def set_account
    if !self.pender_data.nil? && !self.pender_data['author_url'].blank?
      self.account = Account.create_for_source(self.pender_data['author_url'])
      self.save!
    end
  end

  def pender_result_is_a_media
    errors.add(:base, 'Sorry, this is not a media') if !self.pender_data.nil? && self.pender_data['type'] != 'item'
  end

  def url_is_unique
    unless self.url.nil?
      existing = Media.where(url: self.url).first
      errors.add(:base, "Media with this URL exists and has id #{existing.id}") unless existing.nil?
    end
  end

  def validate_pender_result_and_retry
    self.validate_pender_result(false, true)
  end
end
