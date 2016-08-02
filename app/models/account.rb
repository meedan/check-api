class Account < ActiveRecord::Base
  include PenderData
  
  attr_accessible
  attr_readonly :url
  
  has_paper_trail on: [:create, :update]
  belongs_to :user
  belongs_to :source
  has_many :medias

  validates_presence_of :url
  validates :url, uniqueness: true, unless: 'CONFIG["allow_duplicated_urls"]'
  validate :validate_pender_result, on: :create

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
      source.slogan = data['description'].blank? ? 'No description available' : data['description']
      source.save!
      self.source = source
      self.save!
    end
  end
end
