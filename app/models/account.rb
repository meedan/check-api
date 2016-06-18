class Account < ActiveRecord::Base
  attr_accessible

  belongs_to :user
  belongs_to :source
  has_many :media

  validates_presence_of :url
  before_save :set_pender_metadata
  
  serialize :data

  private

  def set_pender_metadata
    self.data =  PenderClient::Request.get_medias(CONFIG['pender_host'], { url: self.url }, CONFIG['pender_key'])
  end
end
