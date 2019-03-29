class SmoochMemeWorker
  include Sidekiq::Worker
  
  sidekiq_options queue: 'smooch', retry: 3
  sidekiq_retries_exhausted { |msg| retry_callback(msg) }

  def self.retry_callback(msg)
    id = msg['args'].first
    d = Dynamic.find(id)
    d.set_fields = { memebuster_last_error: "[#{Time.now}] #{msg['error_message']}" }.to_json
    d.save!
  end

  def perform(id)
    Bot::Smooch.send_meme_to_smooch_users(id)
  end
end
