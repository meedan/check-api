file = File.join(Rails.root, 'config', "sidekiq-#{Rails.env}.yml")
file = File.join(Rails.root, 'config', "sidekiq.yml") unless File.exist?(file)
if File.exist?(file)
  require 'sidekiq/middleware/i18n'

  SIDEKIQ_CONFIG = YAML.load_file(file)

  redis_config = { url: "redis://#{SIDEKIQ_CONFIG[:redis_host]}:#{SIDEKIQ_CONFIG[:redis_port]}/#{SIDEKIQ_CONFIG[:redis_database]}", namespace: "sidekiq_checkapi_#{Rails.env}" }

  Sidekiq.configure_server do |config|
    config.redis = redis_config
  end

  Sidekiq.configure_client do |config|
    config.redis = redis_config
  end
end
