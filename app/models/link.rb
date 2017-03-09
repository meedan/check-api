class Link < Media
  include PenderData
  
  validates :url, presence: true, on: :create
  validate :validate_pender_result, on: :create
  validate :pender_result_is_an_item, on: :create
  validate :url_is_unique, on: :create
  
  after_create :set_pender_result_as_annotation, :set_account

  def domain
    host = URI.parse(self.url).host unless self.url.nil?
    host.nil? ? nil : host.gsub(/^(www|m)\./, '')
  end

  def picture
    path = ''
    begin
      pender_data = JSON.parse(self.annotations.where(annotation_type: 'embed').last.data['embed'])
      path = case self.domain
             when 'twitter.com'
               pender_data['entities']['media'][0]['media_url_https'] || pender_data['entities']['media'][0]['media_url']
             when 'facebook.com'
               pender_data['photos'][0]
             else
               pender_data['picture']
             end
    rescue
    end
    path.to_s
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
      errors.add(:base, I18n.t(:invalid_media_item, default: 'Sorry, this is not a valid media item')) unless self.pender_data['type'] == 'item'
    end
  end

  def url_is_unique
    unless self.url.nil?
      existing = Media.where(url: self.url).first
      errors.add(:base, "Media with this URL exists and has id #{existing.id}") unless existing.nil?
    end
  end
end
