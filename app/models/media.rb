class Media < ActiveRecord::Base
  attr_accessible
  has_paper_trail on: [:create, :update]
  belongs_to :project
  belongs_to :account
  belongs_to :user

  include PenderData

  validates_presence_of :url
  validates :url, uniqueness: true
  validate :validate_pender_result

  has_annotations

  if ActiveRecord::Base.connection.class.name != 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
    serialize :data
  end

  def user_id_callback(value)
    user = User.where(name: value).last
    user.nil? ? nil : user.id
  end

  def account_id_callback(value)
    account = Account.where(url: value).last
    account.nil? ? nil : account.id
  end

  def project_id_callback(value, ids)
    project = ids[value]
    project.nil? ? nil : project
  end
end
