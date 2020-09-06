class SmoochWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker

  sidekiq_options queue: 'smooch', retry: 10

  sidekiq_retry_in { |_count, _exception| 20 }

  def perform(json_message, type, app_id, request_type, annotated)
    annotated = YAML.load(annotated)
    User.current = BotUser.where(login: 'smooch').last
    benchmark.send("smooch_save_#{type}_message") do
      Bot::Smooch.save_message(json_message, app_id, User.current, request_type, annotated)
    end
    benchmark.finish
    User.current = nil
  end
end
