SIDEKIQ_CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'sidekiq.yml'))
Sidekiq.configure_server do |config|
  config.redis = { url: "redis://#{SIDEKIQ_CONFIG[:redis_host]}:#{SIDEKIQ_CONFIG[:redis_port]}/#{SIDEKIQ_CONFIG[:redis_database]}", namespace: "sidekiq_checkapi_#{Rails.env}" }
end
Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{SIDEKIQ_CONFIG[:redis_host]}:#{SIDEKIQ_CONFIG[:redis_port]}/#{SIDEKIQ_CONFIG[:redis_database]}", namespace: "sidekiq_checkapi_#{Rails.env}" }
end
