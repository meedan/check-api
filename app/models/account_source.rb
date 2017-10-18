class AccountSource < ActiveRecord::Base
  attr_accessor :url

  belongs_to :source
  belongs_to :account

  validates_presence_of :source_id, :account_id

  before_validation :set_account, on: :create

  notifies_pusher on: :save,
                  event: 'source_updated',
                  targets: proc { |as| [as.source] },
                  data: proc { |as| as.to_json }

  private

  def set_account
    if self.account_id.blank? && !self.url.blank?
      self.account =  Account.create_for_source(self.url, nil, true)
    end
  end

end
