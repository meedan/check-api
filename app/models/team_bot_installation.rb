class TeamBotInstallation < ActiveRecord::Base
  belongs_to :team
  belongs_to :team_bot

  validates :team_id, :team_bot_id, presence: true
  validate :can_be_installed_if_approved, on: :create
  validate :can_be_installed_if_limited, on: :create

  after_create :give_access_to_team
  after_destroy :remove_access_from_team

  private

  def can_be_installed_if_approved
    if self.team_bot.present? && !self.team_bot.approved && self.team_id != self.team_bot.team_author_id
      errors.add(:base, I18n.t(:bot_not_approved_for_installation))
    end
  end

  def can_be_installed_if_limited
    if self.team_bot.present? && self.team_bot.limited && !self.team.send("get_limits_#{self.team_bot.identifier}") && self.team_bot.team_author_id != self.team_id
      errors.add(:base, I18n.t(:bot_limited_team_not_pro))
    end
  end

  def give_access_to_team
    if TeamUser.where(user_id: self.team_bot.bot_user_id, team_id: self.team_id).last.nil?
      team_user = TeamUser.new
      team_user.role = self.team_bot.role
      team_user.status = 'member'
      team_user.user_id = self.team_bot.bot_user_id
      team_user.team_id = self.team_id
      team_user.skip_check_ability = true
      team_user.save!
    end
  end

  def remove_access_from_team
    team_bot = self.team_bot
    unless team_bot.nil?
      team_user = TeamUser.where(user_id: team_bot.bot_user_id, team_id: self.team_id).last
      unless team_user.nil?
        team_user.skip_check_ability = true
        team_user.destroy!
      end
    end
  end
end
