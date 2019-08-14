class SmoochPingWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker

  sidekiq_options queue: 'smooch_ping', retry: 0

  def perform(uid, app_id)
    Bot::Smooch.send_message_to_user(uid, Bot::Smooch.i18n_t(:smooch_bot_window_closing)) if Bot::Smooch.get_installation('smooch_app_id', app_id)
  end
end
