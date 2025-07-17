require 'error_codes'

class AccountSource < ApplicationRecord
  include CheckElasticSearch
  attr_accessor :url

  belongs_to :source, optional: true
  belongs_to :account, optional: true

  validates_presence_of :source_id, :account_id

  before_validation :set_account, on: :create

  validates :account_id, uniqueness: { scope: :source_id }

  validate :is_unique_per_team, on: :create

  after_create :update_source_overridden_cache

  private

  def set_account
    if self.account_id.blank? && !self.url.blank?
      self.account =  Account.create_for_source(self.url, self.source, true)
    end
  end

  def is_unique_per_team
    if self.source_id && self.source.team.nil?
      # Duplicate for user profile.
      as = AccountSource.where(source_id: self.source_id, account_id: self.account_id).last
      errors.add(:base, "This account already exists") unless as.nil?
    end
  end

  def update_source_overridden_cache
    a = self.source.accounts.first
    self.source.cache_source_overridden if !a.nil? && a.id == self.account_id
  end
end
