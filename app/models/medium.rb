class Medium < ActiveRecord::Base
  attr_accessible

  belongs_to :project
  belongs_to :account
  belongs_to :user

  validates_presence_of :url
  before_save :set_pender_metadata

  serialize :data

  private

  def set_pender_metadata
    self.data =  PenderClient::Request.get_medias(CONFIG['pender_host'], { url: self.url }, CONFIG['pender_key'])
  end
end
