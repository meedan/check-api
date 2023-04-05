file = File.join(Rails.root, 'config', "sidekiq-#{Rails.env}.yml")
file = File.join(Rails.root, 'config', 'sidekiq.yml') unless File.exist?(file)
require File.join(Rails.root, 'lib', 'middleware_sidekiq_server_retry')
require "sidekiq"
require "sidekiq/cloudwatchmetrics"

Sidekiq::Extensions.enable_delay!
Sidekiq::CloudWatchMetrics.enable!(
  namespace: "sidekiq_checkapi_#{Rails.env}",
  additional_dimensions: { "ClusterName" => "Sidekiq-#{ENV['DEPLOY_ENV']}" } )

# Only enable CloudWatch metrics for Live, not Travis or other
# integration test environments.
#
if "#{ENV['DEPLOY_ENV']}" == 'live'
  Sidekiq::CloudWatchMetrics.enable!(
    namespace: "sidekiq_checkapi_#{Rails.env}",
    additional_dimensions: { "ClusterName" => "Sidekiq-#{ENV['DEPLOY_ENV']}" } )
end

REDIS_CONFIG = {}
if File.exist?(file)
  require 'sidekiq/middleware/i18n'
  require 'connection_pool'

  SIDEKIQ_CONFIG = YAML.load_file(file)

  Rails.application.configure do
    config.active_job.queue_adapter = :sidekiq
    redis_url = { host: SIDEKIQ_CONFIG[:redis_host], port: SIDEKIQ_CONFIG[:redis_port], db: SIDEKIQ_CONFIG[:redis_database], namespace: "cache_checkapi_#{Rails.env}" }
    config.cache_store = :redis_store, redis_url
  end

  redis_config = { url: "redis://#{SIDEKIQ_CONFIG[:redis_host]}:#{SIDEKIQ_CONFIG[:redis_port]}/#{SIDEKIQ_CONFIG[:redis_database]}", namespace: "sidekiq_checkapi_#{Rails.env}", network_timeout: 5 }
  REDIS_CONFIG.merge!(redis_config)

  Sidekiq.configure_server do |config|
    config.redis = redis_config

    config.server_middleware do |chain|
      chain.add ::Middleware::Sidekiq::Server::Retry
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = redis_config
    config.logger.level = Logger::WARN if Rails.env.test?
  end

end
