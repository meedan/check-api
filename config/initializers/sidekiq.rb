file = File.join(Rails.root, 'config', "sidekiq-#{Rails.env}.yml")
file = File.join(Rails.root, 'config', 'sidekiq.yml') unless File.exist?(file)
require File.join(Rails.root, 'lib', 'middleware_sidekiq_server_retry')
require 'airbrake/sidekiq'

Sidekiq::Logging.logger = Rails.logger.child

Airbrake.add_filter(Airbrake::Sidekiq::RetryableJobsFilter.new)

Sidekiq.configure_server do |config|
  # logging with sidekiq context
  Sidekiq::Logging.logger.before_log = lambda do |data|
    ctx = Thread.current[:sidekiq_context]
    break unless ctx
    items = ctx.map {|c| c.split(' ') }.flatten
    data[:sidekiq_context] = items if items.any?
  end

  # Replace default error handler
  config.error_handlers << lambda do |ex, ctx|
    Sidekiq::Logging.logger.warn(ex, job: ctx[:job]) # except job_str
  end
end

REDIS_CONFIG = {}
if File.exist?(file)
  require 'sidekiq/middleware/i18n'
  require 'connection_pool'

  SIDEKIQ_CONFIG = YAML.load_file(file)

  redis_config = { url: "redis://#{SIDEKIQ_CONFIG[:redis_host]}:#{SIDEKIQ_CONFIG[:redis_port]}/#{SIDEKIQ_CONFIG[:redis_database]}", namespace: "sidekiq_checkapi_#{Rails.env}" }
  REDIS_CONFIG.merge!(redis_config)

  Sidekiq.configure_server do |config|
    config.redis = redis_config
    config.server_middleware do |chain|
      chain.add ::Middleware::Sidekiq::Server::Retry
    end
  end

  Sidekiq.configure_client do |config|
    config.redis = redis_config
  end
end
