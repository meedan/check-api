require 'active_support/concern'

module TeamSlackNotifications
  extend ActiveSupport::Concern

  EVENT_TYPES = ['any_activity', 'status_changed']

  SLACK_NOTIFICATIONS_JSON_SCHEMA = File.read(File.join(Rails.root, 'public', 'slack_json_schema.json'))

  included do
    validate :slack_channel_format

    def status_changed(model, values)
      model.is_annotation? && model.annotation_type == 'verification_status' && values.include?(model.status)
    end
  end

  def slack_notifications_json_schema
    pm = ProjectMedia.new(team_id: self.id)
    statuses_objs = ::Workflow::Workflow.options(pm, pm.default_project_media_status_type)[:statuses]
    namespace = OpenStruct.new({
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

  def slack_notifications_enabled=(enabled)
    self.send(:set_slack_notifications_enabled, enabled)
  end

  def slack_webhook=(webhook)
    self.send(:set_slack_webhook, webhook)
  end

  def slack_notifications=(slack_notifications)
    self.send(:set_slack_notifications, JSON.parse(slack_notifications))
  end

  private

  def slack_channel_format
    invalid_channels = []
    unless self.get_slack_notifications.blank?
      self.get_slack_notifications.map(&:with_indifferent_access).each do |notification|
        channel = notification[:slack_channel]
        invalid_channels << channel if !channel.blank? && /\A[#@]/.match(channel).nil?
      end
    end
    self.errors.add(:base, I18n.t(:slack_channel_format_wrong)) unless invalid_channels.blank?
  end
end
