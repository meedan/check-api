require 'active_support/concern'

module TeamSlackNotifications
  extend ActiveSupport::Concern

  EVENT_TYPES = ['any_activity', 'status_changed', 'item_added']

  SLACK_NOTIFICATIONS_JSON_SCHEMA = File.read(File.join(Rails.root, 'public', 'slack_json_schema.json'))

  included do
    def status_changed(pm, values)
      values.include?(pm.last_status)
    end

    def item_added(pm, values)
      values.map(&:to_i).include?(pm.project_id)
    end

    def slack_notification_action(pm, value)
      pm.send_slack_notification(nil, value)
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
    any_activity = all_events.map(&:with_indifferent_access).find{ |event| event[:event_type] == 'any_activity' }
    any_activity.blank? ? nil : any_activity[:slack_channel]
  end

  def apply_slack_notifications_events(pm)
    return if pm.skip_notifications || RequestStore.store[:skip_notifications]
    self.apply_notifications(pm).each do |notification|
      self.slack_notification_action(pm, notification[:slack_channel])
    end
  end

  def apply_notifications(pm)
    all_slack_notifications = self.get_slack_notifications || []
    any_activity = []
    other_events = []
    all_slack_notifications.map(&:with_indifferent_access).each do |notification|
      if EVENT_TYPES.include?(notification[:event_type])
        if notification[:event_type] == 'any_activity'
          any_activity << notification
        elsif self.send(notification[:event_type], pm, notification[:values])
          other_events << notification
        end
      end
    end
    other_events.blank? ? any_activity : [other_events.first]
  end
end
