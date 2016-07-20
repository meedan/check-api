class Media < ActiveRecord::Base
  attr_accessible
  attr_readonly :url
  
  has_paper_trail on: [:create, :update]
  belongs_to :account
  belongs_to :user
  has_many :project_medias
  has_many :projects , through: :project_medias
  has_annotations
  
  include PenderData

  validates_presence_of :url
  #validates :url, uniqueness: true
  validate :validate_pender_result, on: :create

  if ActiveRecord::Base.connection.class.name != 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
    serialize :data
  end

  def user_id_callback(value, _mapping_ids = nil)
    user = User.where(name: value).last
    user.nil? ? nil : user.id
  end

  def account_id_callback(value, _mapping_ids = nil)
    account_id = _mapping_ids[value]
  end

end
