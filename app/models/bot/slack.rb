class Bot::Slack < ActiveRecord::Base

  check_settings

  def self.default
    Bot::Slack.where(name: 'Slack Bot').last
  end

  def should_notify?(team, model)
    team.present? && !model.skip_notifications && team.setting(:slack_notifications_enabled).to_i === 1
  end

  def should_notify_super_admin?(model)
    should_notify_annotation?(model) && !model.skip_notifications && self.setting(:slack_notifications_enabled).to_i === 1
  end

  def should_notify_annotation?(model)
    (model.is_annotation? && model.annotated_type != 'ProjectMedia') ? false : true
  end

  def notify_slack(model)
    # Get team & project
    p = self.get_project(model)
    t = self.get_team(model, p)

    if self.should_notify?(t, model)
      webhook = t.setting(:slack_webhook)
      channel = p.setting(:slack_channel) unless p.nil?
      channel ||= t.setting(:slack_channel)
      message = model.slack_notification_message if model.respond_to?(:slack_notification_message)
      self.send_slack_notification(model, webhook, channel, message)
    end
    self.notify_super_admin(model, t, p)
  end

  def notify_super_admin(model, team, project)
    if self.should_notify_super_admin?(model)
      webhook = self.setting(:slack_webhook)
      channel = self.setting(:slack_channel)
      message = model.slack_notification_message if model.respond_to?(:slack_notification_message)
      unless message.blank?
        prefix = team.name
        prefix += ": #{project.title}" unless project.nil?
        message  = "[#{prefix}] - #{message}"
      end
      self.send_slack_notification(model, webhook, channel, message)
    end
  end

  def send_slack_notification(model, webhook, channel, message)
    return if webhook.blank? || channel.blank? || message.blank?

      data = {
        payload: {
          channel: channel,
          text: message.gsub('\\n', "\n")
        }.to_json
      }

      Rails.env === 'test' ? self.request_slack(model, webhook, data) : SlackNotificationWorker.perform_async(webhook, YAML::dump(data), YAML::dump(User.current))
  end

  def request_slack(model, webhook, data)
    self.request(webhook, data)
    model.sent_to_slack = true
  end

  def request(webhook, data)
    url = URI.parse(webhook)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url.request_uri)
    request.set_form_data(data)
    http.request(request)
  end
  class << self
    def to_slack(text)
      # https://api.slack.com/docs/message-formatting#how_to_escape_characters
      { '&' => '&amp;', '<' => '&lt;', '>' => '&gt;' }.each { |k,v|
        text = text.gsub(k,v)
      }
      text
    end

    def to_slack_url(url, text)
      url.insert(0, "#{CONFIG['checkdesk_client']}/") unless url.start_with? "#{CONFIG['checkdesk_client']}/"
      text = self.to_slack(text)
      text = text.tr("\n", ' ')
      "<#{url}|#{text}>"
    end

    def to_slack_quote(text)
      text = I18n.t(:blank) if text.blank?
      text = self.to_slack(text)
      text.insert(0, "\n") unless text.start_with? "\n"
      text.gsub("\n", "\n>")
    end
  end

  protected

  def get_project(model)
    p = model if model.class.to_s == 'Project'
    p = model.project if model.respond_to?(:project)
    if model.is_annotation? && model.annotated_type == 'ProjectMedia'
      p = model.annotated.project
    end
    p
  end

  def get_team(model, project)
    t = model.team if model.respond_to?(:team)
    t ||= project.team unless project.nil?
    t
  end

  module SlackMessage
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def create_or_update_slack_message(options = {})
        send("after_#{options[:on]}", "call_slack_api_#{options[:endpoint]}") 
      end

      def call_slack_api(id, endpoint)
        obj = self.find(id)
        obj.annotated.get_annotations('slack_message').each do |annotation|
          id = annotation.load.get_field_value('slack_message_id')
          channel = annotation.load.get_field_value('slack_message_channel')
          attachments = annotation.load.get_field_value('slack_message_attachments')
          query = obj.slack_message_parameters(id, channel, attachments)
          Net::HTTP.get_response(URI("https://slack.com/api/chat.#{endpoint}?" + URI.encode_www_form(query.merge({ channel: channel, token: CONFIG['slack_token'] }))))
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
      self.class.delay_for(1.second, retry: 0).call_slack_api(self.id, endpoint) if !CONFIG['slack_token'].blank? && self.client_mutation_id != 'from_slack'
    end
  end

  Comment.class_eval do
    include ::Bot::Slack::SlackMessage

    create_or_update_slack_message on: :create, endpoint: :post_message
    
    def slack_message_parameters(id, _channel, _attachments)
      # Not localized yet because Check Slack Bot is only in English for now
      { thread_ts: id, text: 'Comment by ' + self.annotator.name + ': ' + self.text }
    end
  end

  Status.class_eval do
    include ::Bot::Slack::SlackMessage
    
    create_or_update_slack_message on: :update, endpoint: :update

    def slack_message_parameters(id, _channel, attachments)
      pm = self.annotated

      label = ''
      I18n.with_locale(:en) do
        statuses = pm.project.team.get_media_verification_statuses || Status.core_verification_statuses('media')
        statuses = statuses.with_indifferent_access['statuses']
        statuses.each { |status| label = status['label'] if status['id'] == pm.last_status }
      end

      json = JSON.parse(attachments)
      json[0]['title'] = "#{label.upcase}: #{pm.title}"
      json[0]['color'] = pm.last_status_color
      json[0]['fields'][0]['value'] = pm.get_versions_log_count
      json[0]['fields'][1]['value'] = "#{pm.completed_tasks_count}/#{pm.all_tasks.size}"
      json[0]['fields'][3]['value'] = "<!date^#{pm.updated_at.to_i}^{date} {time}|#{pm.updated_at.to_i}>"
      json[0]['fields'][4]['value'] = pm.project.title

      tags = pm.get_annotations('tag').map(&:tag)
      json[0]['fields'][5] = { title: 'Tags', value: tags.join(', '), short: true } if tags.size > 0
      
      { ts: id, attachments: json.to_json }
    end
  end
end
