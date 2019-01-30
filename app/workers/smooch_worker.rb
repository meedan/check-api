class SmoochWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker
  
  sidekiq_options queue: 'smooch'

  def perform(json_message, type, app_id)
    benchmark.send("smooch_save_#{type}_message") do
      Bot::Smooch.save_message(json_message, app_id)
    end
    benchmark.finish
  end
end
