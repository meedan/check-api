class SmoochWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker

  sidekiq_options queue: 'smooch', retry: 3

  sidekiq_retry_in { |_count, _exception| 20 }

  def perform(message_json, type, app_id, request_type, associated_id = nil, associated_class = nil)
    User.current = BotUser.smooch_user
    # This is a temp code for existing jobs and should remove it in next deployment
    annotated = begin YAML.load(associated_id) rescue nil end
    unless annotated.nil?
      associated_id = annotated.id
      associated_class = annotated.class.name
    end
    benchmark.send("smooch_save_#{type}_message") do
      Bot::Smooch.save_message(message_json, app_id, User.current, request_type, associated_id, associated_class)
    end
    benchmark.finish
    User.current = nil
  end
end
