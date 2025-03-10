class Bot::Slack < BotUser

  check_settings

  def self.default
    Bot::Slack.first || Bot::Slack.new
  end

  def self.send_message_to_slack_conversation(text, token, channel)
    query = {
      response_type: 'in_channel',
      text: text,
      token: token,
      channel: channel
    };
    Net::HTTP.get_response(URI('https://slack.com/api/chat.postMessage?' + URI.encode_www_form(query)))
  end

  def should_notify?(target, model)
    RequestStore.store[:skip_notifications].blank? &&
    !model.skip_notifications && target.present? &&
    target.respond_to?(:setting) &&
    target.setting(:slack_notifications_enabled).to_i === 1 &&
    User.current.present?
  end

  def notify_slack(model, event = nil)
    t = model.team
    if self.should_notify?(t, model)
      webhook = t.setting(:slack_webhook)
      channel = t.get_slack_notifications_channel(model)
      attachment = model.slack_notification_message(event) if model.respond_to?(:slack_notification_message)
      attachment = {
        pretext: attachment
      } if attachment.is_a? String
      self.send_notification(model, webhook, channel, attachment)
    end
    self.notify_admin(model, t, attachment)
  end

  def notify_admin(model, team, attachment = nil)
    if self.should_notify?(self, model)
      webhook = self.setting(:slack_webhook)
      channel = self.setting(:slack_channel)
      attachment ||= model.slack_notification_message if model.respond_to?(:slack_notification_message)
      attachment = {
        pretext: attachment
      } if attachment.is_a? String
      unless attachment&.dig(:pretext).blank?
        prefix = team.name
        attachment[:pretext] = "[#{prefix}] #{attachment[:pretext]}"
      end
      self.send_notification(model, webhook, channel, attachment)
    end
  end

  def send_notification(model, webhook, channel, attachment)
    return if webhook.blank? || channel.blank? || attachment.blank?

    data = {
      payload: {
        channel: channel,
        attachments: [self.prepare_attachment(attachment)]
      }.to_json
    }

    Rails.env == 'test' ? self.request_slack(model, webhook, data) : SlackNotificationWorker.perform_async(webhook, YAML::dump(data), YAML::dump(User.current))
  end

  def prepare_attachment(attachment)
    attachment.dig(:fields)&.delete_if { |f| f[:value].blank? }
    # fallback is the text used in the browser notification message
    attachment[:fallback] ||= attachment[:pretext]
    attachment
  end

  def request_slack(model, webhook, data)
    url = URI.parse(webhook)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url.request_uri)
    request.set_form_data(data)
    http.request(request) unless Rails.env == 'test'
    model.sent_to_slack = true unless model.nil?
  end

  class << self
    def to_slack(text, truncate = true)
      return nil if text.blank?
      # https://api.slack.com/docs/message-formatting#how_to_escape_characters
      { '&' => '&amp;', '<' => '&lt;', '>' => '&gt;' }.each { |k,v|
        text = text.gsub(k,v)
      }
      truncate ? text.truncate(280) : text
    end

    def to_slack_url(url, text, truncate = true)
      url.insert(0, "#{CheckConfig.get('checkdesk_client')}/") unless url.start_with? "#{CheckConfig.get('checkdesk_client')}/"
      text = self.to_slack(text, truncate).to_s.tr("\n", ' ')
      "<#{url}|#{text}>"
    end
  end

  module SlackMessage
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def call_slack_api(id, mutation_id, endpoint, uid)
        user = User.where(id: uid.to_i).last
        obj = self.find_by_id(id)
        annotated = obj.annotated if obj.respond_to?(:annotated)
        annotated = obj.annotated&.annotated if obj.is_a?(Dynamic) && obj.annotated_type == 'Task'
        annotated = obj.annotation&.annotated if obj.is_a?(DynamicAnnotation::Field)
        return unless annotated.respond_to?(:get_annotations)
        slack_message_id = mutation_id.to_s.match(/^fromSlackMessage:(.*)$/)
        annotated.get_annotations('slack_message').each do |annotation|
          id = annotation.load.get_field_value('slack_message_id')
          next if !slack_message_id.nil? && id == slack_message_id[1]
          channel = annotation.load.get_field_value('slack_message_channel')
          attachments = annotation.load.get_field_value('slack_message_attachments')
          query = obj.slack_message_parameters(id, channel, attachments, user, endpoint)
          Net::HTTP.get_response(URI("https://slack.com/api/chat.#{endpoint}?" + URI.encode_www_form(query.merge({ channel: channel, token: annotation.load.get_field_value('slack_message_token') }))))
        end
      end
    end

    def call_slack_api_post_message
      call_slack_api('postMessage')
    end

    def call_slack_api_update
      call_slack_api('update')
    end

    def call_slack_api(endpoint)
      if !DynamicAnnotation::AnnotationType.where(annotation_type: 'slack_message').last.nil? && !User.current.nil?
        self.class.delay_for(1.second, retry: 0).call_slack_api(self.id, self.client_mutation_id, endpoint, User.current.id)
      end
    end
  end

  ProjectMedia.class_eval do
    def update_slack_message_attachments(attachments)
      self.set_json_for_message_attachments(attachments, self.status_label_for_slack_notification)
    end

    def status_label_for_slack_notification
      label = ''
      I18n.with_locale(:en) do
        statuses = Workflow::Workflow.options(self, self.default_project_media_status_type)
        statuses = statuses.with_indifferent_access['statuses']
        statuses.each { |status| label = status['label'] if status['id'] == self.last_status }
      end
      label
    end

    def set_json_for_message_attachments(attachments, label)
      json = attachments ? JSON.parse(attachments) : []
      if json[0]
        json[0]['title'] = "#{label.upcase}: #{self.title.to_s.truncate(140)}"
        json[0]['text'] = self.description.to_s.truncate(500)
        json[0]['color'] = self.last_status_color
        json[0]['fields'][1]['value'] = "<!date^#{self.updated_at.to_i}^{date} {time}|#{self.updated_at.to_i}>" if json[0]['fields']
      end
      json.to_json
    end
  end

  Task.class_eval do
    include ::Bot::Slack::SlackMessage

    after_save :call_slack_api_post_message, if: proc { |t| t.should_send_slack_notification_to_thread? }

    def should_send_slack_notification_to_thread?
      self.saved_change_to_data? && !self.team_task_id
    end

    def slack_message_parameters(id, _channel, _attachments, user, _endpoint)
      event = self.updated_at > self.created_at ? 'edit' : 'create'
      params = { user: user.name.to_s, title: self.label.to_s }
      text = I18n.t("slack.messages.#{self.fieldset}_#{event}", **params)
      { thread_ts: id, text: text }
    end
  end

  Dynamic.class_eval do
    include ::Bot::Slack::SlackMessage

    after_save :call_slack_api_post_message, if: proc { |d| d.should_send_slack_notification_to_thread? }

    def should_send_slack_notification_to_thread?
      !(self.annotation_type =~ /^task_response_/).nil?
    end

    def slack_message_parameters(id, _channel, _attachments, user, _endpoint)
      event = self.updated_at > self.created_at ? 'edit' : 'create'
      task = Task.find(self.annotated_id)
      answer = self.values(['response'], '')['response']
      params = { user: user.name.to_s, title: task.label.to_s, answer: answer }
      text = I18n.t("slack.messages.#{task.fieldset}_answer_#{event}", **params)
      { thread_ts: id, text: text }
    end
  end

  DynamicAnnotation::Field.class_eval do
    include ::Bot::Slack::SlackMessage

    after_save :call_slack_api_update, if: proc { |f| f.should_send_slack_notification_to_thread? }
    after_update :call_slack_api_post_message, if: proc { |f| f.should_send_slack_notification_to_thread? }

    def should_send_slack_notification_to_thread?
      self.annotation_type == 'verification_status' && self.value != self.value_before_last_save && ['verification_status_status', 'content', 'title'].include?(self.field_name)
    end

    def slack_message_parameters(id, _channel, attachments, user, endpoint)
      if endpoint == 'postMessage'
        value = self.field_name == 'verification_status_status' ? self.annotation.annotated.status_label_for_slack_notification : self.value
        params = { user: user&.name.to_s, value: value }
        text = I18n.t("slack.messages.analysis_#{self.field_name}_changed", **params)
        { thread_ts: id, text: text }
      elsif endpoint == 'update'
        { ts: id, attachments: self.annotation.annotated.update_slack_message_attachments(attachments) }
      end
    end
  end
end
