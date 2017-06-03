class Bot::Slack < ActiveRecord::Base

  include CheckSettings

  def self.default
    Bot::Slack.where(name: 'Slack Bot').last
  end

  def should_notify?(team, model)
    User.current.present? && team.present? && !model.skip_notifications && team.setting(:slack_notifications_enabled).to_i === 1
  end

  def should_notify_super_admin?(model)
    User.current.present? && should_notify_annotation?(model) && !self.skip_notifications && self.setting(:slack_notifications_enabled).to_i === 1
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
    self.notify_super_admin(model, t, p) if self.should_notify_super_admin?(model)
  end

  def notify_super_admin(model, team, project)
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

end
