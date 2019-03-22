class SmoochPingWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  
  sidekiq_options queue: 'smooch_ping'

  def perform(uid, app_id)
    Bot::Smooch.get_installation('smooch_app_id', app_id)
    Bot::Smooch.send_message_to_user(uid, I18n.t(:smooch_bot_window_closing))
  end
end
