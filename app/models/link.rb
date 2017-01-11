class Link < Media
  include PenderData
  
  attr_accessor :duplicated_of

  validates :url, presence: true, on: :create
  validate :validate_pender_result, on: :create
  validate :pender_result_is_an_item, on: :create
  validate :url_is_unique, on: :create
  
  after_create :set_pender_result_as_annotation, :set_account
  after_rollback :duplicate

  def domain
    host = URI.parse(self.url).host unless self.url.nil?
    host.nil? ? nil : host.gsub(/^(www|m)\./, '')
  end

  private

  def set_account
    unless self.pender_data.nil?
      account = Account.new
      account.url = self.pender_data['author_url']
      if account.save
        self.account = account
      else
        self.account = Account.where(url: account.url).last
      end
      self.save!
    end
  end

  def pender_result_is_an_item
    unless self.pender_data.nil?
      errors.add(:base, 'Sorry, this is not a valid media item') unless self.pender_data['type'] == 'item'
    end
  end

  def url_is_unique
    unless self.url.nil?
      existing = Media.where(url: self.url).first
      self.duplicated_of = existing
      errors.add(:base, "Media with this URL exists and has id #{existing.id}") unless existing.nil?
    end
  end

  def duplicate
    dup = self.duplicated_of
    unless dup.blank?
      dup.project_id = self.project_id
      dup.origin = self.origin
      dup.associate_to_project
      return false
    end
    true
  end
end
