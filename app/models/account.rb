class Account < ActiveRecord::Base
  include PenderData

  attr_accessible
  attr_readonly :url

  has_paper_trail on: [:create, :update]
  belongs_to :user
  belongs_to :source
  belongs_to :team
  has_many :medias

  validates_presence_of :url
  validate :validate_pender_result, on: :create
  validate :pender_result_is_a_profile, on: :create
  validate :url_is_unique

  after_create :create_source

  if ActiveRecord::Base.connection.class.name != 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
    serialize :data
  end

  def provider
    self.data['provider']
  end

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def source_id_callback(value, _mapping_ids = nil)
    source = Source.where(name: value).last
    source.nil? ? nil : source.id
  end

  private

  def create_source
    if self.source.nil?
      data = self.data
      source = Source.new
      source.avatar = data['picture']
      source.name = data['title'].blank? ? 'Untitled' : data['title']
      source.slogan = data['description'].to_s
      source.save!
      self.source = source
      self.save!
    end
  end

  def pender_result_is_a_profile
    errors.add(:base, 'Sorry, this is not a profile') if !self.data.nil? && self.data['type'] != 'profile'
  end

  def url_is_unique
    if !CONFIG['allow_duplicated_urls']
      existing = Account.where(url: self.url).where('source_id IS NOT NULL').first
      unless existing.nil?
        errors.add(:base, "Account with this URL exists and has source id #{existing.source_id}")
      end
    end
  end
end
