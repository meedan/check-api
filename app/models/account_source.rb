class AccountSource < ActiveRecord::Base
  attr_accessor :url, :disable_es_callbacks

  belongs_to :source
  belongs_to :account

  validates_presence_of :source_id, :account_id

  before_validation :set_account, on: :create

  validate :is_unique_per_team, on: :create

  after_create :add_elasticsearch_account
  
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
      errors.add(:base, "This account already exists in project #{ps.project_id} and has id #{ps.id}") unless ps.blank?
    end
  end

  def add_elasticsearch_account
    return if self.disable_es_callbacks
    ts = self.source.get_team_source
    unless ts.nil?
      parent = Base64.encode64("TeamSource/#{ts.id}")
      accounts = self.source.accounts
      accounts.each do |a|
        a.add_update_media_search_child('account_search', %w(ttile description username), {}, parent)
      end unless accounts.blank?
    end
  end

  protected

  def check_duplicate_accounts
    sources = AccountSource.where(source: Team.current.sources, account_id: self.account_id).map(&:source_id) unless Team.current.nil?
    ProjectSource.where(source_id: sources).last unless sources.blank?
  end

end
