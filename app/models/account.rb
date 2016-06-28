class Account < ActiveRecord::Base
  attr_accessible :url, :user_id, :source_id
  has_paper_trail on: [:create, :update]
  belongs_to :user
  belongs_to :source
  has_many :medias

  validates_presence_of :url
  before_save :set_pender_metadata

  if ActiveRecord::Base.connection.class.name != 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
    serialize :data
  end

  private

  def set_pender_metadata
    self.data =  PenderClient::Request.get_medias(CONFIG['pender_host'], { url: self.url }, CONFIG['pender_key'])
  end

  def user_id_callback(value)
    user = User.where(name: value).last
    user.nil? ? nil : user.id
  end
end
