require 'active_support/concern'

module TeamAssociations
  extend ActiveSupport::Concern

  included do
    has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }, class_name: 'Version'

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

    has_annotations
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
end
