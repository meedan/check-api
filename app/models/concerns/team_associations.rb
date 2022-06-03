require 'active_support/concern'

module TeamAssociations
  extend ActiveSupport::Concern

  included do
    has_many :projects, dependent: :destroy
    has_many :accounts # No "dependent: :destroy" because they will be anonymized
    has_many :team_users, dependent: :destroy
    has_many :users, through: :team_users
    has_many :sources # No "dependent: :destroy" because they will be anonymized
    has_many :tag_texts, dependent: :destroy
    has_many :team_tasks, dependent: :destroy
    has_many :project_medias, dependent: :destroy
    has_many :bot_resources, dependent: :destroy
    has_many :saved_searches, dependent: :destroy
    has_many :project_groups, dependent: :destroy

    has_annotations
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

  def country_teams
    data = {}
    unless self.country.nil?
      Team.where(country: self.country).find_each{ |t| data[t.id] = t.name }
    end
    data
  end

  def recent_projects
    self.projects
  end
end
