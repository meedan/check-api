class Bot::Slack < ActiveRecord::Base

  def self.default
    Bot::Slack.where(name: 'Slack Bot').last
  end

  def should_notify?(team, model)
    User.current.present? && team.present? && !model.skip_notifications && team.setting(:slack_notifications_enabled).to_i === 1
  end

  def sent_to_slack
    @sent_to_slack
  end

  def sent_to_slack=(bool)
    @sent_to_slack = bool
  end

  def notify_slack(model)
    t, p = self.get_team_and_project(model)
    if self.should_notify?(t, model)
      webhook = t.setting(:slack_webhook)
      channel = p.setting(:slack_channel) unless p.nil?
      channel ||= t.setting(:slack_channel)
      message = model.slack_notification_message if model.respond_to?(:slack_notification_message)
      puts "webhook --- #{webhook} ---- CH #{channel} ---- MS #{message}"
      return if webhook.blank? || channel.blank? || message.blank?

      data = {
        payload: {
          channel: channel,
          text: message.gsub('\\n', "\n")
        }.to_json
      }

      self.request_slack(webhook, data)
      # Rails.env === 'test' ? model.request_slack(webhook, data) : CheckNotifications::Slack::Worker.perform_async(webhook, data)
    end
  end

  def request_slack(webhook, data)
    self.request(webhook, data)
    self.sent_to_slack = true
  end

  def request(webhook, data)
    url = URI.parse(webhook)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url.request_uri)
    request.set_form_data(data)
    http.request(request)
  end

  def get_team_and_project(model)
    t = model.team if model.respond_to?(:team)
    p = model if model.class.to_s == 'Project'
    if model.is_annotation?
      p = model.annotated.project
      t = model.current_team
    end
    p = model.annotated.project if model.is_annotation?
    p = model.project if p.nil? && model.respond_to?(:project)
    t ||= p.team unless p.nil?
    return t, p
  end

end
