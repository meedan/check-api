class Account < ActiveRecord::Base
  attr_accessible
  has_paper_trail on: [:create, :update]
  belongs_to :user
  belongs_to :source
  has_many :medias

  include PenderData

  validates_presence_of :url
  validates :url, uniqueness: true
  validate :validate_pender_result

  if ActiveRecord::Base.connection.class.name != 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
    serialize :data
  end

  def user_id_callback(value)
    user = User.where(name: value).last
    user.nil? ? nil : user.id
  end
end
