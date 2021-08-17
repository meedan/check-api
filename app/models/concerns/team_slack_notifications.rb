require 'active_support/concern'

module TeamSlackNotifications
  extend ActiveSupport::Concern

  EVENT_TYPES = ['any_activity', 'status_changed', 'item_added']

  SLACK_NOTIFICATIONS_JSON_SCHEMA = File.read(File.join(Rails.root, 'public', 'slack_json_schema.json'))

  included do
    def status_changed(model, values)
      model.is_annotation? && model.annotation_type == 'verification_status' && values.include?(model.status)
    end

    def item_added(model, values)
      model.class.name == 'ProjectMedia' && values.map(&:to_i).include?(model.project_id)
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

  def get_slack_notifications_channel(model)
    notification = self.apply_notifications(model)
    notification.blank? ? nil : notification.with_indifferent_access[:slack_channel]
  end

  def apply_notifications(model)
    all_slack_notifications = self.get_slack_notifications || []
    any_activity = []
    other_events = []
    all_slack_notifications.map(&:with_indifferent_access).each do |notification|
      if EVENT_TYPES.include?(notification[:event_type])
        if notification[:event_type] == 'any_activity'
          any_activity << notification
        elsif self.send(notification[:event_type], model, notification[:values])
          other_events << notification
        end
      end
    end
    other_events.blank? ? any_activity.first : other_events.first
  end
end
