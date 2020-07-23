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

  def notify_slack(model)
    t = model.team

    if self.should_notify?(t, model)
      webhook = t.setting(:slack_webhook)
      channel ||= t.setting(:slack_channel)
      attachment = model.slack_notification_message if model.respond_to?(:slack_notification_message)
      attachment = {
        pretext: attachment
      } if attachment.is_a? String
      self.send_notification(model, webhook, channel, attachment)
    end
    self.notify_admin(model, t)
  end

  def notify_admin(model, team)
    if self.should_notify?(self, model)
      webhook = self.setting(:slack_webhook)
      channel = self.setting(:slack_channel)
      attachment = model.slack_notification_message if model.respond_to?(:slack_notification_message)
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
      url.insert(0, "#{CONFIG['checkdesk_client']}/") unless url.start_with? "#{CONFIG['checkdesk_client']}/"
      text = self.to_slack(text, truncate).to_s.tr("\n", ' ')
      "<#{url}|#{text}>"
    end
  end

  module SlackMessage
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def create_or_update_slack_message(options = {})
        events = options[:on] || []
        [events].flatten.each do |event|
          params = {}
          params[:if] = options[:if] if options.has_key?(:if)
          send("after_#{event}", "call_slack_api_#{options[:endpoint]}", params)
        end
      end

      def call_slack_api(id, mutation_id, endpoint)
        obj = self.where(id: id).last
        return if obj.nil?
        obj = obj.annotation.load if obj.is_a?(DynamicAnnotation::Field)
        return unless obj.annotated.respond_to?(:get_annotations)
        slack_message_id = mutation_id.to_s.match(/^fromSlackMessage:(.*)$/)
        obj.annotated.get_annotations('slack_message').each do |annotation|
          id = annotation.load.get_field_value('slack_message_id')
          next if !slack_message_id.nil? && id == slack_message_id[1]
          channel = annotation.load.get_field_value('slack_message_channel')
          attachments = annotation.load.get_field_value('slack_message_attachments')
          query = obj.slack_message_parameters(id, channel, attachments)
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
      self.class.delay_for(1.second, retry: 0).call_slack_api(self.id, self.client_mutation_id, endpoint) unless DynamicAnnotation::AnnotationType.where(annotation_type: 'slack_message').last.nil?
    end

    # The default behavior is to update an existing Slack message

    def slack_message_parameters(id, _channel, attachments)
      { ts: id, attachments: self.annotated.update_slack_message_attachments(attachments) }
    end
  end

  ProjectMedia.class_eval do
    def update_slack_message_attachments(attachments)
      label = ''
      I18n.with_locale(:en) do
        statuses = Workflow::Workflow.options(self, self.default_project_media_status_type)
        statuses = statuses.with_indifferent_access['statuses']
        statuses.each { |status| label = status['label'] if status['id'] == self.last_status }
      end
      set_json_for_message_attachments(attachments, label)
    end

    private

    def set_json_for_message_attachments(attachments, label)
      json = JSON.parse(attachments)
      if json[0]
        json[0]['title'] = "#{label.upcase}: #{self.title.to_s.truncate(140)}"
        json[0]['text'] = self.description.to_s.truncate(500)
        json[0]['color'] = self.last_status_color
        if json[0]['fields']
          tags = self.get_annotations('tag').map(&:tag)
          data = {
            0 => self.get_versions_log_count,
            2 => "<!date^#{self.updated_at.to_i}^{date} {time}|#{self.updated_at.to_i}>"
          }
          data[4] = { title: 'Tasks Completed', value: "#{self.completed_tasks_count}/#{self.all_tasks.size}", short: true } if self.all_tasks.size > 0
          data[5] = { title: 'Tags', value: tags.join(', '), short: true } if tags.size > 0
          data.each do |k, v|
            json[0]['fields'][k]['value'] = v if json[0]['fields'][k]
          end
        end
      end
      json.to_json
    end

  end

  Comment.class_eval do
    include ::Bot::Slack::SlackMessage

    create_or_update_slack_message on: :create, endpoint: :post_message

    def slack_message_parameters(id, _channel, _attachments)
      { thread_ts: id, text: "Comment by #{self.annotator.name}: #{self.text}" }
    end
  end

  Dynamic.class_eval do
    include ::Bot::Slack::SlackMessage

    def slack_message_parameters(id, _channel, attachments)
      { ts: id, attachments: self.annotated.update_slack_message_attachments(attachments) }
    end
  end

  DynamicAnnotation::Field.class_eval do
    include ::Bot::Slack::SlackMessage

    create_or_update_slack_message on: :update, endpoint: :update, if: proc { |f| f.annotation.annotation_type.match(/_status$/) }
    create_or_update_slack_message on: [:update, :create], endpoint: :update, if: proc { |f| f.annotation.annotation_type == 'metadata' }
  end
end
