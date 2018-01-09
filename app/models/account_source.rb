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
    return if self.account_id.blank? || self.source_id.blank?
    as = AccountSource.where(account_id: self.account_id).last
    unless as.nil?
      if self.source.type == 'Profile'
        errors.add(:base, "This account already exists")
      else
        ps = get_project_sources(as.source_id)
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
  end

  def get_project_sources(sid)
    projects = Team.current.projects.map(&:id) unless Team.current.nil?
    ProjectSource.where(project_id: projects, source_id: sid).last unless projects.blank?
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

end
