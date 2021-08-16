require 'active_support/concern'

module TeamSlackNotifications
  extend ActiveSupport::Concern

  EVENT_TYPES = ['any_activity', 'status_is', 'folder_is']

  SLACK_NOTIFICATIONS_JSON_SCHEMA = File.read(File.join(Rails.root, 'public', 'slack_json_schema.json'))

  included do
    validate :notifications_labels
    
    def status_is(pm, values)
      pm.last_status == values
    end

    def folder_is(pm, values)
      pm.project_id == values.to_i
    end

    def slack_notification_action(pm, value)
      pm.send_slack_notification(nil, value)
    end

    def self.rule_id(rule)
      rule.with_indifferent_access[:label].parameterize.tr('-', '_')
    end
  end

  def slack_notifications_json_schema
    pm = ProjectMedia.new(team_id: self.id)
    statuses_objs = ::Workflow::Workflow.options(pm, pm.default_project_media_status_type)[:statuses]
    namespace = OpenStruct.new({
      projects: self.projects.order('title ASC').collect{ |p| { key: p.id, value: p.title } },
      statuses: statuses_objs.collect{ |st| { key: st.with_indifferent_access['id'], value: st.with_indifferent_access['label'] } }
    })
    ERB.new(SLACK_NOTIFICATIONS_JSON_SCHEMA).result(namespace.instance_eval { binding })
  end

  def any_activity_channel
    all_events = self.get_slack_notifications || []
    any_activity = all_events.map(&:with_indifferent_access).find{ |event| event[:condition][:event_type] == 'any_activity' }
    any_activity.blank? ? nil : any_activity[:action][:slack_channel]
  end

  def apply_slack_notifications_events(pm)
    return if pm.skip_notifications || RequestStore.store[:skip_notifications]
    begin
      self.apply_notifications(pm) do |rules_and_actions|
        rules_and_actions[:action].each do |action|
          self.slack_notification_action(pm, action[:slack_channel])
        end
      end
    rescue StandardError => e
      Airbrake.notify(e, params: { team: self.name, project_media_id: pm.id, method: 'apply_slack_notification_events' }) if Airbrake.configured?
      Rails.logger.info "[Slack Notifications] Exception when applying slack notification events to project media #{pm.id} for team #{self.id}"
    end
  end

  def apply_notifications(pm)
    all_rules_and_actions = self.get_slack_notifications || []
    any_activity = []
    other_events = []
    all_rules_and_actions.map(&:with_indifferent_access).each do |rules_and_actions|
      condition = rules_and_actions[:condition] 
      if EVENT_TYPES.include?(condition[:event_type])
        if condition[:event_type] == 'any_activity'
          any_activity << rules_and_actions
        elsif self.send(condition[:event_type], pm, condition[:values])
          other_events << rules_and_actions
        end
      end
    end
    other_events.blank? ? any_activity : [other_events.first]
  end

  private

  def notifications_labels
    labels = []
    unless self.get_slack_notifications.blank?
      self.get_slack_notifications.each do |notification|
        labels << notification.with_indifferent_access['label']
      end
    end
    errors.add(:base, I18n.t(:team_slack_notification_label_invalid)) if !labels.select{ |n| n.blank? }.empty? || labels.uniq.size != labels.size
  end
end
