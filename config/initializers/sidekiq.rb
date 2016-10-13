if File.exist?(File.join(Rails.root, 'config', 'sidekiq.yml'))
  SIDEKIQ_CONFIG = YAML.load_file(File.join(Rails.root, 'config', 'sidekiq.yml'))
  
  redis_config = { url: "redis://#{SIDEKIQ_CONFIG[:redis_host]}:#{SIDEKIQ_CONFIG[:redis_port]}/#{SIDEKIQ_CONFIG[:redis_database]}", namespace: "sidekiq_checkapi_#{Rails.env}" }
  
  Sidekiq.configure_server do |config|
    config.redis = redis_config
  end
  
  Sidekiq.configure_client do |config|
    config.redis = redis_config
  end
end
