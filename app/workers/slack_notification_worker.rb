class SlackNotificationWorker
  include Sidekiq::Worker

  def perform(webhook, data, author)
    data = YAML::load(data)
    author = YAML::load(author)
    current_user = User.current
    User.current = author
    bot = Bot::Slack.default
    bot.request_slack(nil, webhook, data) unless bot.nil?
    User.current = current_user
  end

end
