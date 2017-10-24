class AccountSource < ActiveRecord::Base
  attr_accessor :url

  belongs_to :source
  belongs_to :account

  validates_presence_of :source_id, :account_id

  before_validation :set_account, on: :create

  validate :is_unique_per_team, on: :create
  
  notifies_pusher targets: proc { |as| [as.source] }, data: proc { |as| { id: as.id }.to_json }, on: :save, event: 'source_updated'

  private

  def set_account
    if self.account_id.blank? && !self.url.blank?
      self.account =  Account.create_for_source(self.url, self.source, true)
    end
  end

  def is_unique_per_team
    sources = Source.where(team_id: Team.current.id).joins(:account_sources).where("account_sources.account_id = ?", self.account_id) unless Team.current.nil?
    unless sources.blank?
      ps = ProjectSource.where(source_id: sources.last.id).last
      errors.add(:base, "Account with this URL exists and has source id #{ps.id} in project #{ps.project_id}") unless ps.nil?
    end
  end

end
