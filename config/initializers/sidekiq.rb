file = File.join(Rails.root, 'config', "sidekiq-#{Rails.env}.yml")
file = File.join(Rails.root, 'config', 'sidekiq.yml') unless File.exist?(file)
require File.join(Rails.root, 'lib', 'middleware_sidekiq_server_retry')
if File.exist?(file)
  require 'sidekiq/middleware/i18n'
  require 'connection_pool'

  SIDEKIQ_CONFIG = YAML.load_file(file)

  redis_config = { url: "redis://#{SIDEKIQ_CONFIG[:redis_host]}:#{SIDEKIQ_CONFIG[:redis_port]}/#{SIDEKIQ_CONFIG[:redis_database]}", namespace: "sidekiq_checkapi_#{Rails.env}" }

  Sidekiq.configure_server do |config|
    config.redis = redis_config
    config.error_handlers << Proc.new { |e, context| Airbrake.notify(e, context) if Airbrake.configured? }
    config.server_middleware do |chain|
      chain.add ::Middleware::Sidekiq::Server::Retry
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = redis_config
  end
end
