class SmoochPingWorker
  include Sidekiq::Worker
  include Sidekiq::Status::Worker
  
  sidekiq_options queue: 'smooch_ping'

  def perform(uid, app_id)
    Bot::Smooch.get_installation('smooch_app_id', app_id)
    Bot::Smooch.send_message_to_user(uid, "Sorry, it's taking a while for us to verify this item... if you are still interested, please send a message, otherwise, do nothing")
  end
end
