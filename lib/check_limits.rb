module CheckLimits

  module Validators
    def max_number_was_reached(collection, klass, message)
      if self.team
        limit = self.team.send("get_limits_max_number_of_#{collection}")
        unless limit.nil?
          if klass.where(team_id: self.team_id).count >= limit.to_i
            errors.add(:base, message)
          end
        end
      end
    end
  end

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
          browser_extension: false,
          keep_integration: false
        }
      }
    end

    check_settings :limits

    before_create :set_default_plan
    validate :only_super_admin_can_change_limits
    validate :can_use_custom_statuses
    validate :can_use_checklist

    private

    def set_default_plan
      self.limits = Team.plans[:free] if self.limits.blank?
    end

    def only_super_admin_can_change_limits
      errors.add(:base, I18n.t(:only_super_admin_can_do_this)) if self.limits_changed? && User.current.present? && !User.current.is_admin?
    end

    def can_use_custom_statuses
      if self.get_limits_custom_statuses == false && 
         (!self.get_source_verification_statuses.blank? || !self.get_media_verification_statuses.blank?)
        errors.add(:base, I18n.t(:cant_set_custom_statuses))
      end
    end

    def can_use_checklist
      if self.get_limits_custom_tasks_list == false && !self.get_checklist.blank?
        errors.add(:base, I18n.t(:cant_set_checklist))
      end
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
    validate :team_is_full, on: :create
    
    include ::CheckLimits::Validators

    private

    def team_is_full
      max_number_was_reached(:members, TeamUser, I18n.t(:max_number_of_team_users_reached))
    end
  end

  # Project

  Project.class_eval do
    validate :max_number_of_projects, on: :create
    
    include ::CheckLimits::Validators

    private

    def max_number_of_projects
      max_number_was_reached(:projects, Project, I18n.t(:max_number_of_projects_reached))
    end
  end

  # ProjectMedia & Keep

  ProjectMedia.class_eval do
    validate :can_submit_through_browser_extension, on: :create

    alias_method :get_keep_token_original, :get_keep_token

    def get_keep_token
      self.get_keep_token_original unless self.project.team.get_limits_keep_integration == false
    end

    private

    def can_submit_through_browser_extension
      if !RequestStore[:request].nil? && 
         RequestStore[:request].headers['X-Check-Client'] == 'browser-extension' && 
         self.project && self.project.team && self.project.team.get_limits_browser_extension == false
        errors.add(:base, I18n.t(:cant_create_media_under_this_team_using_extension))
      end
    end
  end
end
