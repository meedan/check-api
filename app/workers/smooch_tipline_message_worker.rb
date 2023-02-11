class SmoochTiplineMessageWorker
  include Sidekiq::Worker

  sidekiq_options queue: 'smooch', retry: 1

  def perform(message_json, payload_json)
    tm = TiplineMessage.from_smooch_payload(message_json, payload_json)
    tm.save!
  end
end
