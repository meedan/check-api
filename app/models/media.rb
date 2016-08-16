class Media < ActiveRecord::Base
  attr_accessible

  has_paper_trail on: [:create, :update]
  belongs_to :account
  belongs_to :user
  has_many :project_medias
  has_many :projects , through: :project_medias
  has_annotations

  include PenderData

  validates_presence_of :url
  validates :url, uniqueness: true, unless: 'CONFIG["allow_duplicated_urls"]'
  validate :validate_pender_result, on: :create

  if ActiveRecord::Base.connection.class.name != 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
    serialize :data
  end

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def account_id_callback(value, mapping_ids)
    mapping_ids[value]
  end
end
