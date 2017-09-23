module CheckLimits

  # Team

  Team.class_eval do
    def self.plans
      {
        free: {
          max_number_of_members: 5,
          max_number_of_projects: 1,
          custom_statuses: false,
          slack_integration: false,
          custom_tasks_list: false,
          browser_extension: false
        }
      }
    end

    check_settings :limits

    before_validation :set_default_plan, on: :create
    validate :only_super_admin_can_change_limits

    private

    def set_default_plan
      self.limits = Team.plans[:free] if self.limits.blank?
    end

    def only_super_admin_can_change_limits
      errors.add(:base, I18n.t(:only_super_admin_can_do_this)) if self.limits_changed? && User.current.present? && !User.current.is_admin?
    end
  end

  # Slack Bot
  
  Bot::Slack.class_eval do
    alias_method :notify_slack_original, :notify_slack

    def notify_slack(model)
      p = self.get_project(model)
      t = self.get_team(model, p)
      unless t.nil?
        self.notify_slack_original(model) unless t.get_limits_slack_integration == false
      end
    end
  end

  # TeamUser

  TeamUser.class_eval do
    validate :max_number_of_members, on: :create

    private

    def max_number_of_members
      if self.team
        limit = self.team.get_limits_max_number_of_members
        unless limit.nil?
          if TeamUser.where(team_id: self.team_id).count >= limit.to_i
            errors.add(:base, I18n.t(:max_number_of_team_users_reached))
          end
        end
      end
    end
  end

  # Project

  Project.class_eval do
    validate :max_number_of_projects, on: :create

    private

    def max_number_of_projects
      if self.team
        limit = self.team.get_limits_max_number_of_projects
        unless limit.nil?
          if Project.where(team_id: self.team_id).count >= limit.to_i
            errors.add(:base, I18n.t(:max_number_of_projects_reached))
          end
        end
      end
    end
  end
end
