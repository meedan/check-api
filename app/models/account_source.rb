class AccountSource < ActiveRecord::Base
  include CheckElasticSearch
  attr_accessor :url

  belongs_to :source
  belongs_to :account

  validates_presence_of :source_id, :account_id

  before_validation :set_account, on: :create

  validates :account_id, uniqueness: { scope: :source_id }

  validate :is_unique_per_team, on: :create

  after_create :update_source_overridden_cache

  after_commit :destroy_elasticsearch_account, on: :destroy, if: proc { |as| !as.account.nil? && as.account.destroyed? }

  notifies_pusher targets: proc { |as| [as.source] }, data: proc { |as| { id: as.id }.to_json }, on: :save, event: 'source_updated'

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
    else
      ps = self.check_duplicate_accounts
      unless ps.blank?
        error = {
          message: I18n.t(:account_exists, project_id: ps.project_id, project_source_id: ps.id),
          code: 'ERR_OBJECT_EXISTS',
          data: {
            project_id: ps.project_id,
            type: 'source',
            id: ps.id
          }
        }
        raise error.to_json
      end
    end
  end

  def update_source_overridden_cache
    a = self.source.accounts.first
    self.source.cache_source_overridden if !a.nil? && a.id == self.account_id
  end

  def destroy_elasticsearch_account
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    parents = self.get_parents
    parents.each do |parent|
      self.account.destroy_es_items('accounts', 'destroy_doc_nested', parent)
    end
  end

  protected

  def check_duplicate_accounts
    sources = AccountSource.where(source: Team.current.sources, account_id: self.account_id).map(&:source_id) unless Team.current.nil?
    ProjectSource.where(source_id: sources).last unless sources.blank?
  end

  def get_parents
    ProjectSource.where(source_id: self.source)
  end

end
