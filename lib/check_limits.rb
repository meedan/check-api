module CheckLimits

  module Validators
    def max_number_was_reached(collection, klass, message)
      if self.team
        limit = self.team.send("get_limits_max_number_of_#{collection}")
        unless limit.to_i === 0
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
          browser_extension: false
        }
      }
    end

    check_settings :limits

    before_validation :fix_json_editor_values
    before_create :set_default_plan
    validate :only_super_admin_can_change_limits
    validate :can_use_custom_statuses

    def fix_json_editor_values
      return if !self.limits_changed?
      self.limits.update(self.limits) { |k,v| [true, false].include?(Team.plans[:free][k.to_sym]) ? !(v.to_i.zero?) : v.to_i }
    end

    def plan
      plan = 'pro'
      plan = 'free' if self.get_limits_max_number_of_projects.to_i > 0
      plan
    end

    private

    def set_default_plan
      self.limits = Team.plans[:free] if self.limits.blank? && !self.is_being_copied
    end

    def only_super_admin_can_change_limits
      errors.add(:base, I18n.t(:only_super_admin_can_do_this)) if self.limits_changed? && User.current.present? && !User.current.is_admin?
    end

    def can_use_custom_statuses
      blank = true
      ::Workflow::Workflow.workflow_ids.each do |id|
        ['media', 'source'].each do |type|
          blank = false unless self.send("get_#{type}_#{id.pluralize}").blank?
        end
      end
      errors.add(:base, I18n.t(:cant_set_custom_statuses)) if self.get_limits_custom_statuses == false && !blank
    end
  end

  # Team Task
  
  TeamTask.class_eval do
    validate :can_use_team_tasks

    private

    def can_use_team_tasks
      if self.team && self.team.get_limits_custom_tasks_list == false
        errors.add(:base, I18n.t(:cant_create_team_task))
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
        if t.get_limits_slack_integration == false
          self.notify_super_admin(model, t, p)
        else
          self.notify_slack_original(model)
        end
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
    include ::CheckLimits::Validators

    validate :max_number_of_projects, on: :create

    private

    def max_number_of_projects
      max_number_was_reached(:projects, Project, I18n.t(:max_number_of_projects_reached))
    end
  end

  # ProjectMedia

  ProjectMedia.class_eval do
    validate :can_submit_through_browser_extension, on: :create

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
