class Account < ActiveRecord::Base
  attr_accessible
  has_paper_trail on: [:create, :update]
  belongs_to :user
  belongs_to :source
  has_many :medias

  include PenderData

  validates_presence_of :url
  #validates :url, uniqueness: true
  validate :validate_pender_result, on: :create
  attr_readonly :url

  if ActiveRecord::Base.connection.class.name != 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
    serialize :data
  end

  def user_id_callback(value, _mapping_ids = nil)
    user = User.where(name: value).last
    user.nil? ? nil : user.id
  end

  def source_id_callback(value, _mapping_ids = nil)
    source = Source.where(name: value).last
    source.nil? ? nil : source.id
  end

end
