class Link < Media
  include PenderData

  validates :url, presence: true, on: :create
  validate :validate_pender_result_and_retry, on: :create
  validate :url_is_unique, :url_max_size, on: :create

  after_create :set_pender_result_as_annotation, :set_account

  def domain
    host = Addressable::URI.encode(self.url, Addressable::URI).host unless self.url.nil?
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
      path = ''
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
    published_time.is_a?(Numeric) ? Time.at(published_time) : Time.parse(published_time)
  end

  def media_type
    self.get_saved_pender_data['provider']
  end

  def self.normalized(url, pender_key = nil)
    l = Link.new url: url, pender_key: pender_key
    l.valid?
    l.url
  end

  private

  def set_account
    if !self.pender_data.nil? && !self.pender_data['author_url'].blank?
      self.account = Account.create_for_source(self.pender_data['author_url'], nil, false, false, self.pender_data[:pender_key])
      self.save!
    end
  end

  def url_is_unique
    unless self.url.nil?
      existing = Media.where(url: self.url).first
      errors.add(:base, "Media with this URL exists and has id #{existing.id}") unless existing.nil?
    end
  end

  def url_max_size
    # Use 2k as max size to stay within safe limits for a unique URL index in PostgreSQL as max size is 2712 bytes.
    errors.add(:base, "Media URL exceeds the maximum size (2000 bytes)") if !self.url.nil? && self.url.bytesize > CheckConfig.get('url_max_size', 2000, :integer)
  end

  def validate_pender_result_and_retry
    self.validate_pender_result(false, true)
    # raise error for invalid links
    raise self.handle_pender_error(self.pender_error_code) if self.pender_error
  end
end
