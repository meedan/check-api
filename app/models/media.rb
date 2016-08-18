class Media < ActiveRecord::Base
  attr_accessible

  has_paper_trail on: [:create, :update]
  belongs_to :account
  belongs_to :user
  has_many :project_medias
  has_many :projects, through: :project_medias
  has_annotations

  include PenderData

  validates_presence_of :url
  validate :validate_pender_result, on: :create
  validate :pender_result_is_an_item, on: :create
  validate :url_is_unique, on: :create

  before_validation :set_user, on: :create
  after_create :set_account

  if ActiveRecord::Base.connection.class.name != 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
    serialize :data
  end

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def account_id_callback(value, mapping_ids)
    mapping_ids[value]
  end

  private

  def set_user
    self.user = self.current_user unless self.current_user.nil? 
  end

  def set_account
    account = Account.new
    account.url = self.data['author_url']
    if account.save
      self.account = account
    else
      self.account = Account.where(url: account.url).last
    end
    self.save!
  end

  def pender_result_is_an_item
    unless self.data.nil?
      errors.add(:base, 'Sorry, this is not a valid media item') unless self.data['type'] == 'item'
    end
  end

  def url_is_unique
    if !CONFIG['allow_duplicated_urls']
      existing = Media.where(url: self.url).first
      errors.add(:base, "Media with this URL exists and has id #{existing.id}") unless existing.nil?
    end
  end
end
