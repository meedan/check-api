require 'active_support/concern'

module TeamAssociations
  extend ActiveSupport::Concern

  included do
    has_many :accounts # No "dependent: :destroy" because they will be anonymized
    has_many :team_users, dependent: :destroy
    has_many :team_bot_installations, class_name: "TeamBotInstallation"
    has_many :users, through: :team_users
    has_many :sources # No "dependent: :destroy" because they will be anonymized
    has_many :tag_texts, dependent: :destroy
    has_many :team_tasks, dependent: :destroy
    has_many :project_medias, dependent: :destroy
    has_many :tipline_resources, dependent: :destroy
    has_many :saved_searches, dependent: :destroy
    has_many :feed_teams, dependent: :destroy
    has_many :feeds, through: :feed_teams
    has_many :monthly_team_statistics # No "dependent: :destroy" because we want to retain statistics
    has_many :tipline_messages
    has_many :tipline_newsletters
    has_many :tipline_requests, as: :associated
    has_many :explainers, dependent: :destroy
    has_many :claim_descriptions
    has_many :api_keys

    has_annotations
  end

  # Teams that share feeds with this one
  def shared_teams
    self.feeds.map(&:teams).flatten.uniq
  end

  def team
    self
  end

  def team_bot_installations
    TeamBotInstallation.where(id: self.team_users.where(type: 'TeamBotInstallation').map(&:id))
  end

  def team_bots
    BotUser.joins(:team_users).where('team_users.team_id' => self.id, 'team_users.status' => 'member', 'team_users.type' => 'TeamBotInstallation')
  end

  def team_bots_created
    bots = []
    self.team_bots.each do |bot|
      bots << bot.id if bot.get_team_author_id == self.id
    end
    BotUser.where(id: bots.uniq)
  end

  def bot_users
    self.team_bots_created
  end

  def spam
    ProjectMedia.where({ team_id: self.id, archived: CheckArchivedFlags::FlagCodes::SPAM , sources_count: 0 })
  end

  def trash
    ProjectMedia.where({ team_id: self.id, archived: CheckArchivedFlags::FlagCodes::TRASHED , sources_count: 0 })
  end

  def unconfirmed
    ProjectMedia.where({ team_id: self.id, archived: CheckArchivedFlags::FlagCodes::UNCONFIRMED , sources_count: 0 })
  end

  def trash_size
    {
      project_media: self.trash_count,
    }
  end

  def spam_count
    self.spam.count
  end

  def trash_count
    self.trash.count
  end

  def unconfirmed_count
    self.unconfirmed.count
  end

  def medias_count(obj = nil)
    obj ||= self
    conditions = { archived: [CheckArchivedFlags::FlagCodes::NONE, CheckArchivedFlags::FlagCodes::UNCONFIRMED] }
    conditions['team_id'] = obj.id if obj.class.name == 'Team'
    relationship_type = Team.sanitize_sql(Relationship.confirmed_type.to_yaml)
    ProjectMedia.where(conditions)
    .joins(:media).where('medias.type != ?', 'Blank')
    .joins("LEFT JOIN relationships r ON r.target_id = project_medias.id AND r.relationship_type = '#{relationship_type}'")
    .where('r.id IS NULL').count
  end

  def check_search_team
    check_search_filter
  end

  def search
    self.check_search_team
  end

  def check_search_trash
    check_search_filter({ 'archived' => CheckArchivedFlags::FlagCodes::TRASHED })
  end

  def check_search_unconfirmed
    check_search_filter({ 'archived' => CheckArchivedFlags::FlagCodes::UNCONFIRMED })
  end

  def check_search_spam
    check_search_filter({ 'archived' => CheckArchivedFlags::FlagCodes::SPAM })
  end

  def fact_checks
    FactCheck.joins(:claim_description).where('claim_descriptions.team_id' => self.id)
  end
end
