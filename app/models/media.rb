class Media < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :account
  belongs_to :user

  validates_presence_of :url
  before_save :set_pender_metadata

  has_annotations

  if ActiveRecord::Base.connection.class.name != 'ActiveRecord::ConnectionAdapters::PostgreSQLAdapter'
    serialize :data
  end

  private

  def set_pender_metadata
    self.data =  PenderClient::Request.get_medias(CONFIG['pender_host'], { url: self.url }, CONFIG['pender_key'])
  end
end
